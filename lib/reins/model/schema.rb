module Reins
  module Model
    module Schema
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def columns
          @columns ||= Reins::Model::Base.schema_inspector.columns(table_name)
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

        def truthy?(value)
          [1, "1", true, "true", "t"].include?(value)
        end
      end
    end
  end
end
