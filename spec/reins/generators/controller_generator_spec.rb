require "spec_helper"
require "tmpdir"

RSpec.describe "Reins::Cli generate controller" do
  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        Reins::Cli.start(%w[new myapp])
        Dir.chdir("myapp") { example.run }
      end
    end
  end

  it "writes the controller with the given action methods" do
    Reins::Cli.start(%w[generate controller Posts index show])

    content = File.read("app/controllers/posts_controller.rb")
    aggregate_failures do
      expect(content).to include("class PostsController < ApplicationController")
      expect(content).to match(/def index/)
      expect(content).to match(/def show/)
    end
  end

  it "writes empty view files for each action and does not touch routes.rb" do
    routes_before = File.read("config/routes.rb")
    Reins::Cli.start(%w[generate controller Posts index show])

    aggregate_failures do
      expect(File.exist?("app/views/posts/index.html.erb")).to be(true)
      expect(File.exist?("app/views/posts/show.html.erb")).to be(true)
      expect(File.read("config/routes.rb")).to eq(routes_before)
    end
  end
end
