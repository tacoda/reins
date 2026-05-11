require "thor"
require "rack"
require "reins/core/cli/invoker"
require "reins/adapters/driven/filesystem/real"
require "reins/adapters/driven/puma/server"
require "reins/adapters/driven/system/process_runner"
require "reins/adapters/driven/system/clock"

module Reins
  module Adapters
    module Driving
      module Thor
        # Driving adapter: translates Thor argv parsing into invocations of
        # Reins::Core::Cli::Invoker. Each Thor method is a thin shim that
        # builds the right positional/keyword args, then delegates. No
        # business logic lives here.
        class Cli < ::Thor
          class << self
            attr_writer :invoker

            def invoker
              @invoker ||= Reins::Core::Cli::Invoker.new(default_deps)
            end

            def reset_adapters!
              @invoker = nil
            end

            def default_deps
              {
                file_system: Reins::Adapters::Driven::Filesystem::Real.new,
                server: Reins::Adapters::Driven::Puma::Server.new,
                process_runner: Reins::Adapters::Driven::System::ProcessRunner.new,
                clock: Reins::Adapters::Driven::System::Clock.new
              }
            end
          end

          desc "new NAME", "Create a new Reins project at NAME"
          def new(name)
            self.class.invoker.invoke(:new, name)
            puts "Created #{name}/"
            puts "Now run: cd #{name} && bin/setup"
          end

          desc "server", "Run a local server"
          def server
            root = File.expand_path(Dir.pwd.to_s)
            config = "#{root}/config.ru"
            app = ::Rack::Builder.load_file(config)
            self.class.invoker.invoke(:server, app: app)
          end

          desc "routes", "List all defined routes"
          def routes
            config = File.join(Dir.pwd, "config.ru")
            unless File.exist?(config)
              warn "config.ru not found in #{Dir.pwd}"
              exit 1
            end

            ::Rack::Builder.parse_file(config)
            app = Reins::Application.instances.last

            if app.nil? || app.routes.nil?
              warn "No Reins::Application with routes was loaded from config.ru"
              exit 1
            end

            self.class.invoker.invoke(:routes, app.routes.rules)
          end

          PRESET_FLAGS = Reins::Core::Generators::PortPresets.names.freeze
          PRESET_FLAGS.each do |preset|
            method_option preset, type: :boolean, default: false
          end
          method_option :driving, type: :boolean, default: false
          method_option :driven, type: :boolean, default: false
          method_option :port, type: :string
          method_option :list, type: :boolean, default: false

          desc "generate TYPE [NAME] [field:type ...]",
               "Generate scaffolding (migration / controller / model / scaffold / port / adapter)"
          def generate(type, name = nil, *fields)
            self.class.invoker.invoke(:generate, type, name, fields: fields, options: options.transform_keys(&:to_sym))
          rescue RuntimeError => e
            warn e.message
            exit 1
          end

          desc "test [ARGS...]", "Run the test suite (shells out to `bundle exec rspec`)"
          def test(*)
            self.class.invoker.invoke(:test, *)
          end

          desc "console", "Open IRB with the application loaded"
          def console
            self.class.invoker.invoke(:console)
          end

          map "db:create" => :db_create
          desc "db:create", "Create the configured database"
          def db_create
            self.class.invoker.invoke(:db_create)
            puts "Created #{Reins::Database.path}"
          end

          map "db:drop" => :db_drop
          desc "db:drop", "Drop the configured database"
          def db_drop
            path = self.class.invoker.invoke(:db_drop)
            puts "Dropped #{path}"
          end

          map "db:migrate" => :db_migrate
          desc "db:migrate", "Run pending migrations"
          def db_migrate
            self.class.invoker.invoke(:db_migrate)
          end

          map "db:rollback" => :db_rollback
          desc "db:rollback [STEPS]", "Roll back the last STEPS migrations (default 1)"
          def db_rollback(steps = "1")
            self.class.invoker.invoke(:db_rollback, steps)
          end

          map "db:schema:dump" => :db_schema_dump
          desc "db:schema:dump", "Write db/schema.rb from current database state"
          def db_schema_dump
            self.class.invoker.invoke(:db_schema_dump)
            puts "Wrote db/schema.rb"
          end
        end
      end
    end
  end
end
