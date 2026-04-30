module Reins
  module Model
    class Relation
      include Enumerable

      def initialize(model)
        @model = model
        @wheres = []
        @orders = []
        @limit = nil
        @offset = nil
      end

      def initialize_copy(_other)
        @wheres = @wheres.dup
        @orders = @orders.dup
        @to_a = nil
      end

      def where(*args)
        spawn { |r| r.send(:add_where, args) }
      end

      def order(*args)
        spawn { |r| r.send(:add_order, args) }
      end

      def limit(value)
        spawn { |r| r.instance_variable_set(:@limit, value) }
      end

      def offset(value)
        spawn { |r| r.instance_variable_set(:@offset, value) }
      end

      def each(&)
        to_a.each(&)
      end

      def to_a
        @to_a ||= execute_query
      end

      def first
        spawn { |r| r.instance_variable_set(:@limit, 1) }.to_a.first
      end

      def last
        return to_a.last unless @orders.empty?

        spawn { |r| r.instance_variable_set(:@orders, [reverse_order]) }.first
      end

      def count
        sql, params = build_sql("SELECT COUNT(*) AS c", apply_clauses: true, suppress_order: true)
        result = Reins::Database.connection.execute(sql, params)
        first_value(result)
      end

      def pluck(field)
        sql, params = build_sql("SELECT #{field}", apply_clauses: true)
        result = Reins::Database.connection.execute(sql, params)
        result.map { |row| row.is_a?(Hash) ? row[field.to_s] : row[0] }
      end

      protected

      def add_where(args)
        if args.size == 1 && args[0].is_a?(Hash)
          args[0].each { |k, v| @wheres << ["#{k} = ?", [v]] }
        else
          @wheres << [args[0], args[1..]]
        end
      end

      def add_order(args)
        args.each do |arg|
          case arg
          when Symbol, String
            @orders << "#{arg} ASC"
          when Hash
            arg.each { |k, dir| @orders << "#{k} #{dir.to_s.upcase}" }
          end
        end
      end

      private

      def spawn
        new_relation = dup
        yield new_relation
        new_relation
      end

      def execute_query
        sql, params = build_sql("SELECT *", apply_clauses: true)
        rows = Reins::Database.connection.execute(sql, params)
        rows.map { |row| @model.send(:instantiate_from_row, row_to_hash(row)) }
      end

      def build_sql(prefix, apply_clauses:, suppress_order: false)
        sql = "#{prefix} FROM #{@model.table_name}"
        params = []
        unless @wheres.empty?
          sql += " WHERE #{@wheres.map(&:first).join(' AND ')}"
          params.concat(@wheres.flat_map { |_, p| p })
        end
        if apply_clauses
          sql += " ORDER BY #{@orders.join(', ')}" if !@orders.empty? && !suppress_order
          sql += " LIMIT #{@limit.to_i}" if @limit
          sql += " OFFSET #{@offset.to_i}" if @offset
        end
        [sql, params]
      end

      def reverse_order
        "#{@model.primary_key} DESC"
      end

      def row_to_hash(row)
        return row if row.is_a?(Hash)

        @model.column_names.zip(row).to_h
      end

      def first_value(result)
        row = result.first
        return 0 if row.nil?
        return row["c"] if row.is_a?(Hash)

        row[0]
      end
    end
  end
end
