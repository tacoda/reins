module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins db:drop`. Resets the connection and removes
        # the database file via the FileSystem port. For non-file-backed
        # adapters, future Database subclasses will customize the cleanup.
        class DbDrop
          def initialize(file_system:)
            @file_system = file_system
          end

          def run
            Reins::DatabaseConfig.load!
            path = Reins::Database.path
            Reins::Database.reset!
            @file_system.rm_f(path)
            path
          end
        end
      end
    end
  end
end
