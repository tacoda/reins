require "reins/adapters/driven/sqlite/repository"
require "reins/adapters/driven/sqlite/schema_inspector"
require "reins/adapters/driven/sqlite/schema_migrator"
require "reins/adapters/driven/filesystem/template_store"
require "reins/adapters/driven/filesystem/real"
require "reins/adapters/driven/erubis/template_engine"
require "reins/adapters/driven/puma/server"
require "reins/adapters/driven/system/clock"
require "reins/adapters/driven/system/env_reader"
require "reins/adapters/driven/system/process_runner"
require "reins/adapters/driven/zeitwerk/autoloader"
require "reins/adapters/driven/memory/repository"
require "reins/adapters/driven/memory/schema_inspector"
require "reins/adapters/driven/memory/template_store"
require "reins/adapters/driven/memory/clock"
require "reins/adapters/driven/memory/env_reader"
require "reins/adapters/driven/memory/process_runner"
require "reins/adapters/driven/memory/file_system"
require "reins/adapters/driven/noop/autoloader"

module Reins
  # Named bundles of adapters and gems. A profile is a named answer to two
  # questions:
  #   1. What gems should `reins new` pin in the generated Gemfile?
  #   2. Which concrete adapter does each port get by default at boot?
  #
  # Profiles are data — Hashes keyed by adapter slot, with values that are
  # Procs called lazily so adapters can depend on resources (like the
  # database connection) wired elsewhere.
  module Profile
    REGISTRY = {
      standard: {
        gems: %w[reins-web puma sqlite3 erubis zeitwerk rackup].freeze,
        adapters: {
          repository: -> { Reins::Adapters::Driven::Sqlite::Repository.new(Reins::Database.connection) },
          schema_inspector: -> { Reins::Adapters::Driven::Sqlite::SchemaInspector.new(Reins::Database.connection) },
          schema_migrator: -> { Reins::Adapters::Driven::Sqlite::SchemaMigrator.new(Reins::Database.connection) },
          template_store: -> { Reins::Adapters::Driven::Filesystem::TemplateStore.new },
          template_engine: -> { Reins::Adapters::Driven::Erubis::TemplateEngine.new },
          file_system: -> { Reins::Adapters::Driven::Filesystem::Real.new },
          server: -> { Reins::Adapters::Driven::Puma::Server.new },
          process_runner: -> { Reins::Adapters::Driven::System::ProcessRunner.new },
          env_reader: -> { Reins::Adapters::Driven::System::EnvReader.new },
          clock: -> { Reins::Adapters::Driven::System::Clock.new },
          autoloader: -> { Reins::Adapters::Driven::Zeitwerk::Autoloader.new }
        }.freeze
      }.freeze,

      slim: {
        gems: %w[reins-web rackup].freeze,
        adapters: {}.freeze
      }.freeze,

      test: {
        gems: %w[reins-web rspec].freeze,
        adapters: {
          repository: -> { Reins::Adapters::Driven::Memory::Repository.new },
          schema_inspector: -> { Reins::Adapters::Driven::Memory::SchemaInspector.new },
          template_store: -> { Reins::Adapters::Driven::Memory::TemplateStore.new },
          template_engine: -> { Reins::Adapters::Driven::Erubis::TemplateEngine.new },
          file_system: -> { Reins::Adapters::Driven::Memory::FileSystem.new },
          process_runner: -> { Reins::Adapters::Driven::Memory::ProcessRunner.new },
          env_reader: -> { Reins::Adapters::Driven::Memory::EnvReader.new },
          clock: -> { Reins::Adapters::Driven::Memory::Clock.new },
          autoloader: -> { Reins::Adapters::Driven::Noop::Autoloader.new }
        }.freeze
      }.freeze
    }.freeze

    def self.names
      REGISTRY.keys.sort
    end

    def self.fetch(name)
      REGISTRY.fetch(name.to_sym) do
        raise ArgumentError, "unknown profile: #{name.inspect}; available: #{names.inspect}"
      end
    end
  end
end
