require "reins/ports/driving/command_invoker"
require "reins/core/cli/commands/server"
require "reins/core/cli/commands/test"
require "reins/core/cli/commands/new"
require "reins/core/cli/commands/routes"
require "reins/core/cli/commands/console"
require "reins/core/cli/commands/generate"
require "reins/core/cli/commands/db_create"
require "reins/core/cli/commands/db_drop"
require "reins/core/cli/commands/db_migrate"
require "reins/core/cli/commands/db_rollback"
require "reins/core/cli/commands/db_schema_dump"

module Reins
  module Core
    module Cli
      # Implements the CommandInvoker driving port. Tests and programmatic
      # callers invoke commands by name through this; the Thor adapter does
      # the same after parsing argv. The Invoker owns the command registry
      # and the dependency graph; each command receives the deps it asks for
      # via kwargs.
      class Invoker
        include Reins::Ports::Driving::CommandInvoker

        COMMANDS = {
          server: Commands::Server,
          test: Commands::Test,
          new: Commands::New,
          routes: Commands::Routes,
          console: Commands::Console,
          generate: Commands::Generate,
          db_create: Commands::DbCreate,
          db_drop: Commands::DbDrop,
          db_migrate: Commands::DbMigrate,
          db_rollback: Commands::DbRollback,
          db_schema_dump: Commands::DbSchemaDump
        }.freeze

        def initialize(deps = {})
          @deps = deps
        end

        def invoke(name, *, **)
          command_class = COMMANDS[name.to_sym]
          unless command_class
            raise ArgumentError,
                  "unknown command: #{name.inspect}; available: #{COMMANDS.keys.inspect}"
          end

          command_class.new(**deps_for(command_class)).run(*, **)
        end

        def self.command_names
          COMMANDS.keys
        end

        private

        def deps_for(command_class)
          # NOTE: Method#parameters returns an Array of [kind, name] pairs —
          # not a Hash. Rubocop's Style/HashSlice cop misreads this.
          accepted = command_class.instance_method(:initialize).parameters
                                  .select { |kind, _| %i[keyreq key].include?(kind) } # rubocop:disable Style/HashSlice
                                  .map { |_, name| name }
          @deps.slice(*accepted)
        end
      end
    end
  end
end
