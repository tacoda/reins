module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins db:migrate`. Delegates to Reins::Migrator
        # which runs each pending migration through the SchemaMigrator port.
        class DbMigrate
          def run
            Reins::DatabaseConfig.load!
            Reins::Migrator.new.run
          end
        end
      end
    end
  end
end
