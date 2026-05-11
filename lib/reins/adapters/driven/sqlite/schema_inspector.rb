require "reins/ports/driven/schema_inspector"

module Reins
  module Adapters
    module Driven
      module Sqlite
        # SQLite implementation of the SchemaInspector port. Encapsulates the
        # PRAGMA / sqlite_master queries used to discover a table's columns
        # and the list of user-defined tables. The only place these queries
        # appear in the framework.
        class SchemaInspector
          include Reins::Ports::Driven::SchemaInspector

          SKIP_TABLES = %w[sqlite_sequence schema_migrations].freeze

          def initialize(connection)
            @connection = connection
          end

          def columns(table)
            rows = @connection.execute("PRAGMA table_info(#{table})")
            rows.each_with_object({}) do |row, h|
              name = row.is_a?(Hash) ? row["name"] : row[1]
              type = row.is_a?(Hash) ? row["type"] : row[2]
              h[name] = type
            end
          end

          def tables
            rows = @connection.execute(
              "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
            )
            rows.map { |row| row.is_a?(Hash) ? row["name"] : row[0] }
                .reject { |name| SKIP_TABLES.include?(name) }
          end
        end
      end
    end
  end
end
