require "reins/core/model/query"

module Reins
  module Model
    class Relation
      include Enumerable

      def initialize(model)
        @model = model
        @query = Reins::Core::Model::Query.new(table: @model.table_name)
      end

      def initialize_copy(_other)
        @query = @query.dup
        @to_a = nil
      end

      def where(*args)
        spawn { |r| r.send(:add_where, args) }
      end

      def order(*args)
        spawn { |r| r.send(:add_order, args) }
      end

      def limit(value)
        spawn { |r| r.query.limit = value }
      end

      def offset(value)
        spawn { |r| r.query.offset = value }
      end

      def each(&)
        to_a.each(&)
      end

      def to_a
        @to_a ||= execute_query
      end

      def first
        spawn { |r| r.query.limit = 1 }.to_a.first
      end

      def last
        return to_a.last unless @query.orders.empty?

        spawn { |r| r.send(:replace_orders, [reverse_order]) }.first
      end

      def count
        Reins::Model::Base.repository.count(@query)
      end

      def pluck(field)
        Reins::Model::Base.repository.pluck(@query, field)
      end

      protected

      attr_reader :query

      def add_where(args)
        if args.size == 1 && args[0].is_a?(Hash)
          @query.add_where_hash(args[0])
        else
          @query.add_where_fragment(args[0], args[1..])
        end
      end

      def add_order(args)
        args.each do |arg|
          case arg
          when Symbol, String
            @query.add_order("#{arg} ASC")
          when Hash
            arg.each { |k, dir| @query.add_order("#{k} #{dir.to_s.upcase}") }
          end
        end
      end

      def replace_orders(orders)
        @query.orders.clear
        orders.each { |o| @query.add_order(o) }
      end

      private

      def spawn
        new_relation = dup
        yield new_relation
        new_relation
      end

      def execute_query
        Reins::Model::Base.repository.find_all(@query).map do |row|
          @model.send(:instantiate_from_row, row_to_hash(row))
        end
      end

      def reverse_order
        "#{@model.primary_key} DESC"
      end

      def row_to_hash(row)
        return row if row.is_a?(Hash)

        @model.column_names.zip(row).to_h
      end
    end
  end
end
