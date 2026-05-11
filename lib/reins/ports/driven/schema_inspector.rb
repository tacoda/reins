require "reins/port"

module Reins
  module Ports
    module Driven
      # Driven port. Returns schema information for a table — columns, types,
      # the table list. Used by Reins::Model::Schema to discover the shape of
      # a model's backing store, and by Reins::Schema for db:schema:dump.
      module SchemaInspector
        extend Reins::Port

        direction :driven

        contract  columns: 1,
                  tables: 0
      end
    end
  end
end
