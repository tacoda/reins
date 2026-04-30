require "spec_helper"

class GreetController < Reins::Controller
  def index
    response("Hello!")
  end
end

RSpec.describe Reins::Application do
  include Rack::Test::Methods

  let(:app) do
    application = Reins::Application.new
    application.route do
      match "greet", "greet#index"
    end
    application
  end

  it "returns a successful response for a routed request" do
    get "/greet"
    expect(last_response).to be_ok
  end

  it "renders the controller action body" do
    get "/greet"
    expect(last_response.body).to include("Hello")
  end

  it "registers subclass instances in Reins::Application.instances" do
    subclass = Class.new(Reins::Application)
    instance = subclass.new
    expect(Reins::Application.instances).to include(instance)
  end

  describe "Reins.application" do
    it "returns the most recently constructed Reins::Application instance" do
      first  = Reins::Application.new
      second = Reins::Application.new
      expect(Reins.application).to be(second)
      expect(Reins.application).not_to be(first)
    end
  end

  describe "middleware integration" do
    after { Reins.reset_config! }

    it "runs requests through the configured middleware stack" do
      trace = []
      tracing_mw = Class.new do
        define_method(:initialize) { |app| @app = app }
        define_method(:call) do |env|
          trace << :before
          r = @app.call(env)
          trace << :after
          r
        end
      end

      Reins.configure { |c| c.middleware.use tracing_mw }

      app = Reins::Application.new
      app.route do
        get "/x", ->(_e) { [200, {}, ["ok"]] }
      end
      app.call(Rack::MockRequest.env_for("/x"))

      expect(trace).to eq(%i[before after])
    end
  end
end
