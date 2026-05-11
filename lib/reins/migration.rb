require "reins/errors"

module Reins
  class Migration
    class NotSupported < Reins::Error; end

    def run_up
      if respond_to?(:up)
        up
      elsif respond_to?(:change)
        change
      else
        raise "Migration #{self.class.name} must define `up` or `change`"
      end
    end

    def run_down
      if respond_to?(:down)
        down
      elsif respond_to?(:change)
        @recording_mode = true
        @recorded_ops = []
        change
        @recording_mode = false
        invert_recorded_ops
      else
        raise Reins::IrreversibleMigration, "Migration #{self.class.name} cannot be rolled back"
      end
    end

    def create_table(name, &block)
      return record_op(:create_table, name) if @recording_mode

      td = TableDefinition.new(name)
      block&.call(td)
      schema_migrator.create_table(name, td.columns)
      td.indexes.each { |args| schema_migrator.add_index(*args) }
    end

    def drop_table(name)
      return record_op(:drop_table, name) if @recording_mode

      schema_migrator.drop_table(name)
    end

    def add_column(table, name, type, **)
      return record_op(:add_column, table, name) if @recording_mode

      schema_migrator.add_column(table, name, type)
    end

    def remove_column(table, name)
      return record_op(:remove_column, table, name) if @recording_mode

      schema_migrator.remove_column(table, name)
    end

    def add_index(table, columns, unique: false, name: nil)
      return record_op(:add_index, table, columns) if @recording_mode

      schema_migrator.add_index(table, columns, unique: unique, name: name)
    end

    def remove_index(table, columns_or_name)
      return record_op(:remove_index, table, columns_or_name) if @recording_mode

      schema_migrator.remove_index(table, columns_or_name)
    end

    def rename_column(table, old_name, new_name)
      return record_op(:rename_column, table, old_name, new_name) if @recording_mode

      schema_migrator.rename_column(table, old_name, new_name)
    end

    def change_column(_table, _name, _type, **)
      raise NotSupported,
            "change_column is not supported in SQLite — define explicit up/down with table copy"
    end

    private

    def schema_migrator
      Reins::Model::Base.schema_migrator
    end

    def record_op(operation, *args)
      @recorded_ops << [operation, *args]
    end

    def invert_recorded_ops
      @recording_mode = false
      @recorded_ops.reverse_each do |operation, *args|
        case operation
        when :create_table then drop_table(args[0])
        when :add_column then remove_column(args[0], args[1])
        when :add_index then remove_index(args[0], args[1])
        else
          raise Reins::IrreversibleMigration,
                "operation #{operation} cannot be reversed; define `down`"
        end
      end
    end

    class TableDefinition
      SHORTHAND_TYPES = %i[string text integer float boolean datetime].freeze

      attr_reader :columns, :indexes

      def initialize(name)
        @name = name
        @columns = []
        @indexes = []
      end

      SHORTHAND_TYPES.each do |type|
        define_method(type) do |column_name, **|
          column(column_name, type)
        end
      end

      def column(column_name, type)
        @columns << { name: column_name, type: type }
      end

      def timestamps
        column(:created_at, :datetime)
        column(:updated_at, :datetime)
      end

      def references(name)
        column("#{name}_id", :integer)
        @indexes << [@name, "#{name}_id"]
      end
    end
  end
end
