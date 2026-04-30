require "spec_helper"

class RoutingHomeController < Reins::Controller
  def index
    response("home")
  end
end

class RoutingUsersController < Reins::Controller
  def show
    response("user #{params['id']}")
  end

  def update
    response("updated #{params['id']}")
  end

  def create
    response("created")
  end
end

RSpec.describe "Routing v2" do
  include Rack::Test::Methods

  let(:app) do
    Reins::Application.new.tap do |a|
      a.route do
        root "routing_home#index"

        get  "/users/:id", "routing_users#show"
        post "/users",     "routing_users#create"
        put  "/users/:id", "routing_users#update"

        get "/numbered/:id", "routing_users#show",
            constraints: { id: /\d+/ }

        match "/legacy", "routing_users#show"
      end
    end
  end

  describe "verb DSL" do
    it "matches a GET request and dispatches the controller action" do
      get "/users/42"
      expect(last_response).to be_ok
      expect(last_response.body).to eq("user 42")
    end

    it "does not match a POST to a GET-only path" do
      post "/users/42"
      expect(last_response.status).to eq(405)
    end
  end

  describe "match (back-compat)" do
    it "matches any verb on a path declared with match" do
      get "/legacy"
      expect(last_response).to be_ok

      post "/legacy"
      expect(last_response).to be_ok

      delete "/legacy"
      expect(last_response).to be_ok
    end
  end

  describe "root" do
    it "is shorthand for GET /" do
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to eq("home")
    end
  end

  describe "404 / 405 handling" do
    it "returns 404 when no route matches the path" do
      get "/nope"
      expect(last_response.status).to eq(404)
    end

    it "returns 405 with an Allow header listing accepted verbs" do
      delete "/users/42"
      expect(last_response.status).to eq(405)
      allow_header = last_response.headers["Allow"] || last_response.headers["allow"]
      expect(allow_header).to be_a(String)
      verbs = allow_header.split(/,\s*/)
      expect(verbs).to include("GET", "PUT")
    end
  end

  describe "constraints" do
    it "rejects a path whose segment fails the regex" do
      get "/numbered/abc"
      expect(last_response.status).to eq(404)
    end

    it "accepts a path whose segment passes the regex" do
      get "/numbered/123"
      expect(last_response).to be_ok
      expect(last_response.body).to eq("user 123")
    end
  end
end
