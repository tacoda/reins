require "fileutils"

module Reins
  module Generators
    class AppGenerator
      def initialize(name)
        @name = name
        @target = File.expand_path(name)
      end

      def run
        FileUtils.mkdir_p(@target)
        files.each do |path, content|
          target = File.join(@target, path)
          FileUtils.mkdir_p(File.dirname(target))
          File.write(target, content)
        end
        FileUtils.chmod("+x", File.join(@target, "bin/setup"))
        FileUtils.chmod("+x", File.join(@target, "bin/console"))
        FileUtils.chmod("+x", File.join(@target, "bin/reins"))
      end

      def app_class_name
        @name.split(/[_-]/).map(&:capitalize).join
      end

      private

      def files
        {
          ".gitignore" => gitignore,
          ".rspec" => "--require spec_helper\n--color\n--format documentation\n",
          "Gemfile" => gemfile,
          "README.md" => readme,
          "Rakefile" => rakefile,
          "bin/reins" => bin_reins,
          "bin/setup" => bin_setup,
          "bin/console" => bin_console,
          "config.ru" => config_ru,
          "config/application.rb" => config_application,
          "config/database.yml" => config_database,
          "config/routes.rb" => config_routes,
          "config/environments/development.rb" => env_development,
          "config/environments/test.rb" => env_test,
          "config/environments/production.rb" => env_production,
          "app/controllers/application_controller.rb" => application_controller,
          "app/controllers/welcome_controller.rb" => welcome_controller,
          "app/models/application_record.rb" => application_record,
          "app/views/layouts/application.html.erb" => layout_view,
          "app/views/welcome/index.html.erb" => welcome_view,
          "db/migrate/.keep" => "",
          "public/404.html" => error_page("404"),
          "public/422.html" => error_page("422"),
          "public/500.html" => error_page("500"),
          "spec/spec_helper.rb" => spec_helper,
          "tmp/.keep" => ""
        }
      end

      def gitignore
        <<~TEXT
          /.bundle/
          /db/*.sqlite3
          /log/*.log
          /tmp/*
          !/tmp/.keep
        TEXT
      end

      def gemfile
        <<~RUBY
          source "https://rubygems.org"

          gem "reins-web"
          gem "puma"
          gem "rackup"

          group :development do
            gem "rerun"
          end

          group :development, :test do
            gem "rspec", "~> 3.13"
          end
        RUBY
      end

      def readme
        <<~MD
          # #{app_class_name}

          A Reins app.

          ## Setup

              bin/setup

          ## Run

              bundle exec reins server
        MD
      end

      def rakefile
        <<~RUBY
          require "rspec/core/rake_task"
          RSpec::Core::RakeTask.new(:spec)
          task default: :spec
        RUBY
      end

      def bin_reins
        <<~RUBY
          #!/usr/bin/env ruby
          require "bundler/setup"
          load Gem.bin_path("reins-web", "reins")
        RUBY
      end

      def bin_setup
        <<~SH
          #!/usr/bin/env bash
          set -e
          bundle install
          bundle exec reins db:create
          bundle exec reins db:migrate
        SH
      end

      def bin_console
        <<~RUBY
          #!/usr/bin/env ruby
          require "bundler/setup"
          load Gem.bin_path("reins-web", "reins")
        RUBY
      end

      def config_ru
        <<~RUBY
          require_relative "config/application"

          app = #{app_class_name}::Application.new

          require_relative "config/routes"

          run app
        RUBY
      end

      def config_application
        <<~RUBY
          require "reins"

          db_config = File.expand_path("../config/database.yml", __dir__)
          Reins::DatabaseConfig.load!(path: db_config) if File.exist?(db_config)

          Dir[File.expand_path("../app/**/*.rb", __dir__)].sort.each { |f| require f }

          module #{app_class_name}
            class Application < Reins::Application
            end
          end
        RUBY
      end

      def config_database
        <<~YAML
          development:
            database: db/development.sqlite3
          test:
            database: db/test.sqlite3
          production:
            database: db/production.sqlite3
        YAML
      end

      def config_routes
        <<~RUBY
          Reins.application.route do
            root "welcome#index"
          end
        RUBY
      end

      def env_development
        <<~RUBY
          Reins.configure do |config|
            config.eager_load = false
            config.reload_classes = true
            config.log_level = :debug
          end
        RUBY
      end

      def env_test
        <<~RUBY
          Reins.configure do |config|
            config.eager_load = false
            config.reload_classes = false
            config.log_level = :warn
          end
        RUBY
      end

      def env_production
        <<~RUBY
          Reins.configure do |config|
            config.eager_load = true
            config.reload_classes = false
            config.log_level = :info
            config.middleware.use Rack::Deflater
          end
        RUBY
      end

      def application_controller
        <<~RUBY
          class ApplicationController < Reins::Controller
          end
        RUBY
      end

      def welcome_controller
        <<~RUBY
          class WelcomeController < ApplicationController
            def index
            end
          end
        RUBY
      end

      def application_record
        <<~RUBY
          class ApplicationRecord < Reins::Model::Base
          end
        RUBY
      end

      def layout_view
        <<~ERB
          <!doctype html>
          <html>
            <head>
              <title>#{app_class_name}</title>
            </head>
            <body>
              <%= yield %>
            </body>
          </html>
        ERB
      end

      def welcome_view
        <<~ERB
          <h1>It works!</h1>
          <p>Edit <code>app/views/welcome/index.html.erb</code> to begin.</p>
        ERB
      end

      def error_page(status)
        path = File.expand_path("../../assets/#{status}.html", __dir__)
        File.exist?(path) ? File.read(path) : "<h1>HTTP #{status}</h1>"
      end

      def spec_helper
        <<~RUBY
          ENV["REINS_ENV"] ||= "test"
          require_relative "../config/application"
          require "reins/spec"

          RSpec.configure do |config|
            config.expect_with(:rspec) { |c| c.syntax = :expect }
          end
        RUBY
      end
    end
  end
end
