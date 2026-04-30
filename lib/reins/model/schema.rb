module Reins
  module Model
    module Schema
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def columns
          @columns ||= load_columns
        end

        def column_names
          columns.keys
        end

        def cast(name, value)
          return nil if value.nil?

          case columns[name.to_s]&.upcase
          when "INTEGER" then value.to_i
          when "REAL", "FLOAT", "NUMERIC" then value.to_f
          when "BOOLEAN", "BOOL" then truthy?(value)
          else value
          end
        end

        private

        def load_columns
          rows = Reins::Database.connection.execute("PRAGMA table_info(#{table_name})")
          rows.each_with_object({}) do |row, h|
            name = row.is_a?(Hash) ? row["name"] : row[1]
            type = row.is_a?(Hash) ? row["type"] : row[2]
            h[name] = type
          end
        end

        def truthy?(value)
          [1, "1", true, "true", "t"].include?(value)
        end
      end
    end
  end
end
