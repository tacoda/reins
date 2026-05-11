require "reins/ports/driven/schema_migrator"

module Reins
  module Adapters
    module Driven
      module Sqlite
        # SQLite implementation of the SchemaMigrator port. All DDL (CREATE
        # TABLE / ALTER TABLE / CREATE INDEX) for the framework is constructed
        # here. Migration code builds structured operations; this adapter
        # turns them into SQLite-flavored SQL.
        class SchemaMigrator
          include Reins::Ports::Driven::SchemaMigrator

          TYPE_MAP = {
            string: "VARCHAR(255)",
            text: "TEXT",
            integer: "INTEGER",
            float: "FLOAT",
            boolean: "BOOLEAN",
            datetime: "DATETIME"
          }.freeze

          def initialize(connection)
            @connection = connection
          end

          def create_table(name, columns)
            sql_columns = ["id INTEGER PRIMARY KEY AUTOINCREMENT"]
            sql_columns.concat(columns.map { |c| "#{c[:name]} #{sql_type_for(c[:type])}" })
            execute("CREATE TABLE #{name} (#{sql_columns.join(', ')})")
          end

          def drop_table(name)
            execute("DROP TABLE #{name}")
          end

          def add_column(table, name, type)
            execute("ALTER TABLE #{table} ADD COLUMN #{name} #{sql_type_for(type)}")
          end

          def remove_column(table, name)
            execute("ALTER TABLE #{table} DROP COLUMN #{name}")
          end

          def add_index(table, columns, unique: false, name: nil)
            cols = Array(columns)
            index_name = name || "index_#{table}_on_#{cols.join('_')}"
            execute("CREATE #{'UNIQUE ' if unique}INDEX #{index_name} ON #{table} (#{cols.join(', ')})")
          end

          def remove_index(table, columns_or_name)
            index_name = if columns_or_name.is_a?(String)
                           columns_or_name
                         else
                           "index_#{table}_on_#{Array(columns_or_name).join('_')}"
                         end
            execute("DROP INDEX #{index_name}")
          end

          def rename_column(table, old_name, new_name)
            execute("ALTER TABLE #{table} RENAME COLUMN #{old_name} TO #{new_name}")
          end

          def execute(sql)
            @connection.execute(sql)
          end

          private

          def sql_type_for(type)
            TYPE_MAP[type.to_sym] || type.to_s.upcase
          end
        end
      end
    end
  end
end
