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
end
