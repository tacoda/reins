require "spec_helper"

# Unit specs for the blueprint that each generator produces. These verify the
# pure planning step — no disk involvement, no Dir.chdir.
RSpec.describe "generator blueprints" do
  describe Reins::Generators::ControllerGenerator do
    let(:bp) { described_class.new("Posts", %w[index show]).blueprint }

    it "lists the controller, view files, and spec under the standard paths" do
      paths = bp.files.map(&:first)
      expect(paths).to include(
        "app/controllers/posts_controller.rb",
        "app/views/posts/index.html.erb",
        "app/views/posts/show.html.erb",
        "spec/controllers/posts_controller_spec.rb"
      )
    end

    it "renders the controller with the named action methods" do
      controller = bp.files.find { |path, _| path.end_with?("posts_controller.rb") }
      expect(controller.last).to include("def index", "def show")
    end

    it "has no executable entries" do
      expect(bp.executables).to be_empty
    end
  end

  describe Reins::Generators::ModelGenerator do
    let(:bp) { described_class.new("Post", %w[title:string body:text]).blueprint }

    it "lists the model, migration, and spec" do
      paths = bp.files.map(&:first)
      expect(paths).to include("app/models/post.rb")
      expect(paths.find { |p| p.match?(%r{\Adb/migrate/\d{14}_create_posts\.rb\z}) }).not_to be_nil
      expect(paths).to include("spec/models/post_spec.rb")
    end

    it "renders the migration with the supplied columns" do
      migration = bp.files.find { |path, _| path.include?("create_posts.rb") }
      expect(migration.last).to include(
        "create_table :posts",
        "t.string :title",
        "t.text :body",
        "t.timestamps"
      )
    end
  end

  describe Reins::Generators::AppGenerator do
    let(:bp) { described_class.new("myapp").blueprint }

    it "lists every file in the app skeleton" do
      paths = bp.files.map(&:first)
      expect(paths).to include(
        ".gitignore",
        "Gemfile",
        "Rakefile",
        "config.ru",
        "config/application.rb",
        "config/routes.rb",
        "config/database.yml",
        "config/environments/development.rb",
        "config/environments/test.rb",
        "config/environments/production.rb",
        "app/controllers/application_controller.rb",
        "app/controllers/welcome_controller.rb",
        "app/models/application_record.rb",
        "app/views/layouts/application.html.erb",
        "app/views/welcome/index.html.erb",
        "spec/spec_helper.rb"
      )
    end

    it "marks bin/setup, bin/console, and bin/reins as executable" do
      expect(bp.executables).to include("bin/setup", "bin/console", "bin/reins")
    end
  end

  describe Reins::Generators::ScaffoldGenerator do
    around do |example|
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          Reins::Generators::AppGenerator.new("myapp").run
          Dir.chdir("myapp") { example.run }
        end
      end
    end

    it "lists model, migration, controller, views, partial, and the updated routes.rb" do
      bp = described_class.new("Post", %w[title:string]).blueprint
      paths = bp.files.map(&:first)
      expect(paths).to include(
        "app/models/post.rb",
        "app/controllers/posts_controller.rb",
        "app/views/posts/index.html.erb",
        "app/views/posts/show.html.erb",
        "app/views/posts/new.html.erb",
        "app/views/posts/edit.html.erb",
        "app/views/posts/_form.html.erb",
        "config/routes.rb"
      )
      expect(paths.find { |p| p.match?(%r{\Adb/migrate/\d{14}_create_posts\.rb\z}) }).not_to be_nil
    end

    it "updates routes.rb with `resources :posts`" do
      bp = described_class.new("Post", %w[title:string]).blueprint
      routes = bp.files.find { |path, _| path == "config/routes.rb" }
      expect(routes.last).to include("resources :posts")
    end
  end
end
