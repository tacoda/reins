require "reins/core/generators/blueprint"
require "reins/core/generators/adapter_generator"

module Reins
  module Core
    module Generators
      # Named bundles of port + adapter scaffolds. Each preset returns a
      # Blueprint that lays down one or more adapters against an existing
      # port in the framework. Used by `reins generate port --PRESET`.
      class PortPresets
        DESCRIPTIONS = {
          rack: "Rack driving adapter for the HttpApp port",
          thor: "Thor driving adapter for the CommandInvoker port",
          sqlite: "SQLite driven adapters for Repository, SchemaInspector, SchemaMigrator",
          memory: "In-memory driven test adapters for Repository, FileSystem, SchemaInspector",
          puma: "Puma driven adapter for the Server port",
          filesystem: "Disk-backed driven adapter for the FileSystem port",
          erubis: "Erubis driven adapter for the TemplateEngine port",
          clock: "System driven adapter for the Clock port",
          env: "System driven adapter for the EnvReader port"
        }.freeze

        def self.names
          DESCRIPTIONS.keys.sort
        end

        def self.descriptions
          DESCRIPTIONS
        end

        def self.fetch(name, scope:)
          unless DESCRIPTIONS.key?(name)
            raise ArgumentError,
                  "unknown preset: #{name.inspect}; available: #{names.inspect}"
          end

          new(scope).send("blueprint_for_#{name}")
        end

        def initialize(scope)
          @scope = scope
        end

        private

        def blueprint_for_rack
          driving_adapter(
            name: "app", namespace: "rack",
            port_module_name: "Reins::Ports::Driving::HttpApp",
            port_require: "reins/ports/driving/http_app"
          )
        end

        def blueprint_for_thor
          driving_adapter(
            name: "cli", namespace: "thor",
            port_module_name: "Reins::Ports::Driving::CommandInvoker",
            port_require: "reins/ports/driving/command_invoker"
          )
        end

        def blueprint_for_sqlite
          merge(
            driven_adapter("repository", "sqlite", Reins::Ports::Driven::Repository,
                           "Reins::Ports::Driven::Repository", "reins/ports/driven/repository"),
            driven_adapter("schema_inspector", "sqlite", Reins::Ports::Driven::SchemaInspector,
                           "Reins::Ports::Driven::SchemaInspector", "reins/ports/driven/schema_inspector"),
            driven_adapter("schema_migrator", "sqlite", Reins::Ports::Driven::SchemaMigrator,
                           "Reins::Ports::Driven::SchemaMigrator", "reins/ports/driven/schema_migrator")
          )
        end

        def blueprint_for_memory
          merge(
            driven_adapter("repository", "memory", Reins::Ports::Driven::Repository,
                           "Reins::Ports::Driven::Repository", "reins/ports/driven/repository"),
            driven_adapter("file_system", "memory", Reins::Ports::Driven::FileSystem,
                           "Reins::Ports::Driven::FileSystem", "reins/ports/driven/file_system"),
            driven_adapter("schema_inspector", "memory", Reins::Ports::Driven::SchemaInspector,
                           "Reins::Ports::Driven::SchemaInspector", "reins/ports/driven/schema_inspector")
          )
        end

        def blueprint_for_puma
          driven_adapter("server", "puma", Reins::Ports::Driven::Server,
                         "Reins::Ports::Driven::Server", "reins/ports/driven/server")
        end

        def blueprint_for_filesystem
          driven_adapter("real", "filesystem", Reins::Ports::Driven::FileSystem,
                         "Reins::Ports::Driven::FileSystem", "reins/ports/driven/file_system")
        end

        def blueprint_for_erubis
          driven_adapter("template_engine", "erubis", Reins::Ports::Driven::TemplateEngine,
                         "Reins::Ports::Driven::TemplateEngine", "reins/ports/driven/template_engine")
        end

        def blueprint_for_clock
          driven_adapter("clock", "system", Reins::Ports::Driven::Clock,
                         "Reins::Ports::Driven::Clock", "reins/ports/driven/clock")
        end

        def blueprint_for_env
          driven_adapter("env_reader", "system", Reins::Ports::Driven::EnvReader,
                         "Reins::Ports::Driven::EnvReader", "reins/ports/driven/env_reader")
        end

        def driven_adapter(name, namespace, port_module, port_module_name, port_require)
          AdapterGenerator.new(
            name,
            port_module: port_module,
            port_module_name: port_module_name,
            port_require: port_require,
            direction: :driven,
            scope: @scope,
            namespace: namespace
          ).blueprint
        end

        def driving_adapter(name:, namespace:, port_module_name:, port_require:)
          AdapterGenerator.new(
            name,
            port_module: nil,
            port_module_name: port_module_name,
            port_require: port_require,
            direction: :driving,
            scope: @scope,
            namespace: namespace
          ).blueprint
        end

        def merge(*blueprints)
          blueprints.reduce(Blueprint.new) { |acc, bp| acc.merge(bp) }
        end
      end
    end
  end
end
