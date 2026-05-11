module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins db:schema:dump`. Reads the live schema via
        # the SchemaInspector port and writes db/schema.rb.
        class DbSchemaDump
          def run
            Reins::DatabaseConfig.load!
            Reins::Schema.dump
          end
        end
      end
    end
  end
end
