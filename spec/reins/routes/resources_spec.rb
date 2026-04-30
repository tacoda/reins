require "spec_helper"

class PostsController < Reins::Controller
  def index   = response("index")
  def show    = response("show #{params['id']}")
  def new     = response("new")
  def create  = response("create")
  def edit    = response("edit #{params['id']}")
  def update  = response("update #{params['id']}")
  def destroy = response("destroy #{params['id']}")
end

RSpec.describe "resources expansion" do
  include Rack::Test::Methods

  let(:app) do
    Reins::Application.new.tap do |a|
      a.route do
        resources :posts
      end
    end
  end

  it "exposes the seven RESTful routes" do
    aggregate_failures do
      get "/posts"
      expect(last_response.body).to eq("index")
      get "/posts/new"
      expect(last_response.body).to eq("new")
      post "/posts"
      expect(last_response.body).to eq("create")
      get "/posts/7"
      expect(last_response.body).to eq("show 7")
      get "/posts/7/edit"
      expect(last_response.body).to eq("edit 7")
      put "/posts/7"
      expect(last_response.body).to eq("update 7")
      delete "/posts/7"
      expect(last_response.body).to eq("destroy 7")
    end
  end

  it "routes both PUT and PATCH on the member path to update" do
    put "/posts/7"
    expect(last_response.body).to eq("update 7")

    patch "/posts/7"
    expect(last_response.body).to eq("update 7")
  end
end
