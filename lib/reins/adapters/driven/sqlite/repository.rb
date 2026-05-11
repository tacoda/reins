require "reins/ports/driven/repository"

module Reins
  module Adapters
    module Driven
      module Sqlite
        # SQLite implementation of the Repository port. The only place in the
        # framework where SQL strings are constructed for data reads/writes —
        # the model layer hands over a Reins::Core::Model::Query and an
        # adapter translates.
        class Repository
          include Reins::Ports::Driven::Repository

          def initialize(connection)
            @connection = connection
          end

          def insert(table, attrs)
            cols = attrs.keys
            placeholders = (["?"] * cols.size).join(", ")
            sql = "INSERT INTO #{table} (#{cols.join(', ')}) VALUES (#{placeholders})"
            @connection.execute(sql, cols.map { |c| attrs[c] })
            @connection.last_insert_row_id
          end

          def update(table, attrs, primary_key, primary_value)
            cols = attrs.keys
            set_clause = cols.map { |c| "#{c} = ?" }.join(", ")
            sql = "UPDATE #{table} SET #{set_clause} WHERE #{primary_key} = ?"
            @connection.execute(sql, cols.map { |c| attrs[c] } + [primary_value])
          end

          def delete(table, primary_key, primary_value)
            sql = "DELETE FROM #{table} WHERE #{primary_key} = ?"
            @connection.execute(sql, [primary_value])
          end

          def find_all(query)
            sql, params = build_sql(query, "SELECT *", apply_clauses: true)
            @connection.execute(sql, params)
          end

          def count(query)
            sql, params = build_sql(query, "SELECT COUNT(*) AS c", apply_clauses: true, suppress_order: true)
            row = @connection.execute(sql, params).first
            scalar_from(row, "c")
          end

          def pluck(query, field)
            sql, params = build_sql(query, "SELECT #{field}", apply_clauses: true)
            @connection.execute(sql, params).map { |row| row.is_a?(Hash) ? row[field.to_s] : row[0] }
          end

          def transaction(&)
            @connection.transaction(&)
          end

          private

          def build_sql(query, prefix, apply_clauses:, suppress_order: false)
            sql = "#{prefix} FROM #{query.table}"
            params = []
            unless query.wheres.empty?
              sql += " WHERE #{query.wheres.map(&:first).join(' AND ')}"
              params.concat(query.wheres.flat_map(&:last))
            end
            if apply_clauses
              sql += " ORDER BY #{query.orders.join(', ')}" if !query.orders.empty? && !suppress_order
              sql += " LIMIT #{query.limit.to_i}" if query.limit
              sql += " OFFSET #{query.offset.to_i}" if query.offset
            end
            [sql, params]
          end

          def scalar_from(row, key)
            return 0 if row.nil?
            return row[key] if row.is_a?(Hash)

            row[0]
          end
        end
      end
    end
  end
end
