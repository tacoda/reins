require "spec_helper"
require "reins/cli"
require "tmpdir"

RSpec.describe Reins::Cli do
  describe "#new" do
    it "scaffolds a project directory at the given name" do
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          described_class.start(%w[new myapp])
          expect(Dir.exist?("myapp")).to be(true)
          expect(Dir.exist?("myapp/app/controllers")).to be(true)
          expect(Dir.exist?("myapp/config")).to be(true)
        end
      end
    end

    it "copies the 500.html error page into the new project's public dir" do
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          described_class.start(%w[new myapp])
          expect(File.exist?("myapp/public/500.html")).to be(true)
        end
      end
    end

    it "does not create a stray 'testdir' directory" do
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          described_class.start(%w[new myapp])
          expect(Dir.exist?("testdir")).to be(false)
        end
      end
    end
  end

  describe "#routes" do
    let(:config_ru) { <<~RUBY }
      require "reins"

      class RoutesCliPostsController < Reins::Controller; end

      app = Reins::Application.new
      app.route do
        root "routes_cli_posts#index"
        get "/users/:id", "routes_cli_posts#show", as: :user
        resources :posts
      end
      run app
    RUBY

    it "prints a table with prefix, verb, path, and destination columns" do
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          File.write("config.ru", config_ru)
          output = capture_stdout { described_class.start(%w[routes]) }
          expect(output).to match(/Prefix.*Verb.*URI Pattern.*Controller#Action/)
          expect(output).to match(%r{root\s+GET\s+/\s+routes_cli_posts#index})
          expect(output).to match(%r{user\s+GET\s+/users/:id\s+routes_cli_posts#show})
        end
      end
    end

    it "includes the seven routes from `resources :posts`" do
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          File.write("config.ru", config_ru)
          output = capture_stdout { described_class.start(%w[routes]) }
          aggregate_failures do
            expect(output).to match(%r{GET\s+/posts\s})
            expect(output).to match(%r{POST\s+/posts\s})
            expect(output).to match(%r{GET\s+/posts/new\s})
            expect(output).to match(%r{GET\s+/posts/:id/edit\s})
            expect(output).to match(%r{PUT\s+/posts/:id\s})
            expect(output).to match(%r{DELETE\s+/posts/:id\s})
          end
        end
      end
    end

    it "exits with a helpful message when config.ru is missing" do
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          output = capture_stdout_and_stderr { described_class.start(%w[routes]) }
          expect(output).to match(/config\.ru/i)
        end
      end
    end

    def capture_stdout
      original = $stdout
      $stdout = StringIO.new
      begin
        yield
        $stdout.string
      ensure
        $stdout = original
      end
    end

    def capture_stdout_and_stderr
      orig_out = $stdout
      orig_err = $stderr
      $stdout = StringIO.new
      $stderr = StringIO.new
      begin
        begin
          yield
        rescue SystemExit
          # CLI may exit non-zero — we just want the message
        end
        $stdout.string + $stderr.string
      ensure
        $stdout = orig_out
        $stderr = orig_err
      end
    end
  end

  describe "generate migration" do
    around do |example|
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          FileUtils.mkdir_p("db/migrate")
          example.run
        end
      end
    end

    it "writes a timestamped file with an empty change block" do
      described_class.start(%w[generate migration AddX])
      file = Dir["db/migrate/*.rb"].first
      expect(file).to match(%r{db/migrate/\d{14}_add_x\.rb\z})
      content = File.read(file)
      expect(content).to include("class AddX < Reins::Migration")
      expect(content).to include("def change")
    end

    it "scaffolds add_column calls when given field:type args" do
      described_class.start(%w[generate migration AddTitleToPosts title:string published_at:datetime])
      file = Dir["db/migrate/*.rb"].first
      content = File.read(file)
      aggregate_failures do
        expect(content).to include("add_column :posts, :title, :string")
        expect(content).to include("add_column :posts, :published_at, :datetime")
      end
    end
  end

  describe "db: commands" do
    around do |example|
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          FileUtils.mkdir_p("config")
          FileUtils.mkdir_p("db/migrate")
          File.write("config/database.yml", <<~YAML)
            development:
              database: db/dev.sqlite3
            test:
              database: db/dev.sqlite3
          YAML
          example.run
        ensure
          Reins::Database.reset!
        end
      end
    end

    it "db:create creates the database file" do
      described_class.start(%w[db:create])
      expect(File.exist?("db/dev.sqlite3")).to be(true)
    end

    it "db:drop deletes the database file" do
      described_class.start(%w[db:create])
      described_class.start(%w[db:drop])
      expect(File.exist?("db/dev.sqlite3")).to be(false)
    end

    it "db:migrate runs pending migrations" do
      File.write("db/migrate/20260101000000_create_posts.rb", <<~RUBY)
        class CreatePosts < Reins::Migration
          def change
            create_table(:posts) { |t| t.string :title }
          end
        end
      RUBY

      described_class.start(%w[db:create])
      described_class.start(%w[db:migrate])

      Reins::Database.reset!
      Reins::DatabaseConfig.load!
      rows = Reins::Database.connection.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='posts'"
      )
      expect(rows).not_to be_empty
    end

    it "db:rollback rolls back the most recent migration" do
      File.write("db/migrate/20260101000000_create_posts.rb", <<~RUBY)
        class CreatePosts < Reins::Migration
          def change
            create_table(:posts) { |t| t.string :title }
          end
        end
      RUBY

      described_class.start(%w[db:create])
      described_class.start(%w[db:migrate])
      described_class.start(%w[db:rollback])

      Reins::Database.reset!
      Reins::DatabaseConfig.load!
      rows = Reins::Database.connection.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='posts'"
      )
      expect(rows).to be_empty
    end

    it "console loads config/application.rb and invokes IRB.start" do
      require "irb"
      Reins::Cli.start(%w[new myapp])
      Dir.chdir("myapp") do
        called = false
        allow(IRB).to receive(:start) { called = true }
        Reins::Cli.start(%w[console])
        expect(called).to be(true)
      end
    ensure
      Object.send(:remove_const, :Myapp) if Object.const_defined?(:Myapp)
    end

    it "test invokes `bundle exec rspec` through the ProcessRunner port" do
      fake_runner = Reins::Adapters::Driven::Memory::ProcessRunner.new
      Reins::Cli.invoker = Reins::Core::Cli::Invoker.new(process_runner: fake_runner)

      Reins::Cli.start(%w[test])

      expect(fake_runner.calls.first.first(3)).to eq(%w[bundle exec rspec])
    ensure
      Reins::Cli.reset_adapters!
    end

    it "db:schema:dump writes db/schema.rb" do
      File.write("db/migrate/20260101000000_create_posts.rb", <<~RUBY)
        class CreatePosts < Reins::Migration
          def change
            create_table(:posts) { |t| t.string :title }
          end
        end
      RUBY

      described_class.start(%w[db:create])
      described_class.start(%w[db:migrate])
      described_class.start(%w[db:schema:dump])

      expect(File.exist?("db/schema.rb")).to be(true)
      expect(File.read("db/schema.rb")).to include("create_table")
    end
  end
end
