require_relative "test_helper"

class TestController < Reins::Controller
  def index
    "Hello!"
  end
end

class TestApp < Reins::Application
  def get_controller_and_action(env)
    [TestController, "index"]
  end
end

class ReinsAppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    TestApp.new
  end

  def test_request
    get "/example/route"
    assert last_response.ok?
    body = last_response.body
    assert body["Hello"]
  end
end