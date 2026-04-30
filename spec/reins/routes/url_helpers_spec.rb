require "spec_helper"

class HelpersDummyController < Reins::Controller; end

RSpec.describe "URL helpers" do
  let(:app) do
    Reins::Application.new.tap do |a|
      a.route do
        get "/users/:id", "helpers_dummy#show", as: :user
        resources :posts
      end
    end
  end

  let(:helpers) do
    app # build the routes
    Object.new.extend(Reins::Routes::UrlHelpers)
  end

  describe "as: generates path and url helpers" do
    it "generates <name>_path returning the path with vars filled" do
      expect(helpers.user_path(123)).to eq("/users/123")
    end

    it "accepts a hash form" do
      expect(helpers.user_path(id: 123)).to eq("/users/123")
    end

    it "<name>_url returns an absolute URL when given host" do
      expect(helpers.user_url(123, host: "example.com")).to eq("http://example.com/users/123")
    end

    it "raises a clear error when a required segment value is missing" do
      expect { helpers.user_path }.to raise_error(ArgumentError, /:id/)
    end
  end

  describe "resources" do
    it "generates posts_path, post_path, new_post_path, edit_post_path" do
      expect(helpers.posts_path).to eq("/posts")
      expect(helpers.post_path(7)).to eq("/posts/7")
      expect(helpers.new_post_path).to eq("/posts/new")
      expect(helpers.edit_post_path(7)).to eq("/posts/7/edit")
    end
  end

  describe "mix-in into Controller and View" do
    it "is available on a Reins::Controller subclass instance" do
      app # ensure routes built
      controller = HelpersDummyController.new({})
      expect(controller.user_path(99)).to eq("/users/99")
    end

    it "is available on a Reins::View instance" do
      app
      expect(Reins::View.new.user_path(99)).to eq("/users/99")
    end
  end
end
