module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins db:rollback [STEPS]` (default 1).
        class DbRollback
          def run(steps = "1")
            Reins::DatabaseConfig.load!
            Reins::Migrator.new.rollback(Integer(steps))
          end
        end
      end
    end
  end
end
