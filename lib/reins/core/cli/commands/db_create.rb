module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins db:create`. Loads the database config and
        # ensures the configured store is reachable (a no-op SELECT 1
        # round-trip for SQLite). Future adapters may override.
        class DbCreate
          def initialize(file_system:)
            @file_system = file_system
          end

          def run
            Reins::DatabaseConfig.load!
            @file_system.mkdir_p(File.dirname(Reins::Database.path))
            Reins::Database.connection.execute("SELECT 1")
          end
        end
      end
    end
  end
end
