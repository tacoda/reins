require "spec_helper"
require "tmpdir"

RSpec.describe "Reins::Cli generate scaffold" do
  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        Reins::Cli.start(%w[new myapp])
        Dir.chdir("myapp") { example.run }
      end
    end
  end

  it "writes the model, migration, controller, views, and form partial" do
    Reins::Cli.start(%w[generate scaffold Post title:string])

    aggregate_failures do
      expect(File.exist?("app/models/post.rb")).to be(true)
      expect(Dir["db/migrate/*_create_posts.rb"].first).not_to be_nil
      expect(File.exist?("app/controllers/posts_controller.rb")).to be(true)
      expect(File.exist?("app/views/posts/index.html.erb")).to be(true)
      expect(File.exist?("app/views/posts/show.html.erb")).to be(true)
      expect(File.exist?("app/views/posts/new.html.erb")).to be(true)
      expect(File.exist?("app/views/posts/edit.html.erb")).to be(true)
      expect(File.exist?("app/views/posts/_form.html.erb")).to be(true)
    end
  end

  it "the generated controller has the seven RESTful action methods" do
    Reins::Cli.start(%w[generate scaffold Post title:string])

    content = File.read("app/controllers/posts_controller.rb")
    aggregate_failures do
      %w[index show new create edit update destroy].each do |action|
        expect(content).to match(/def #{action}\b/), "missing action: #{action}"
      end
    end
  end

  it "appends `resources :posts` to config/routes.rb" do
    Reins::Cli.start(%w[generate scaffold Post title:string])
    expect(File.read("config/routes.rb")).to include("resources :posts")
  end
end
