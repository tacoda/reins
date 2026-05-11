require "reins/ports/driven/schema_inspector"

module Reins
  module Adapters
    module Driven
      module Memory
        # In-memory implementation of the SchemaInspector port. Constructed
        # with a Hash of table-name => {column => type}; useful for tests
        # that want to bypass disk and pre-declare the schema.
        class SchemaInspector
          include Reins::Ports::Driven::SchemaInspector

          def initialize(schema = {})
            @schema = schema
          end

          def columns(table)
            @schema[table] || {}
          end

          def tables
            @schema.keys
          end
        end
      end
    end
  end
end
