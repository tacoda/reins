module Reins
  module Core
    module Model
      # Pure value object describing a database read. The model layer builds a
      # Query; the Repository port executes it. The Query knows nothing about
      # SQL — it carries fragments-with-placeholders and lets adapters do the
      # translation.
      class Query
        attr_reader :table, :wheres, :orders
        attr_accessor :limit, :offset

        def initialize(table:)
          @table = table
          @wheres = []
          @orders = []
          @limit = nil
          @offset = nil
        end

        def initialize_copy(_other)
          @wheres = @wheres.dup
          @orders = @orders.dup
        end

        def add_where_fragment(fragment, params)
          @wheres << [fragment, params]
          self
        end

        def add_where_hash(hash)
          hash.each { |k, v| @wheres << ["#{k} = ?", [v]] }
          self
        end

        def add_order(spec)
          @orders << spec
          self
        end

        def ==(other)
          other.is_a?(self.class) &&
            other.table == @table &&
            other.wheres == @wheres &&
            other.orders == @orders &&
            other.limit == @limit &&
            other.offset == @offset
        end
        alias eql? ==

        def hash
          [@table, @wheres, @orders, @limit, @offset].hash
        end
      end
    end
  end
end
