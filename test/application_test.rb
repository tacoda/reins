require_relative "test_helper"

class TestApp < Reins::Application
end

class ReinsAppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    TestApp.new
  end

  def test_request
    get "/"
    assert last_response.ok?
    body = last_response.body
    assert body["Hello"]
  end
end