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
end
