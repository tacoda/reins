require "reins/errors"

module Reins
  class Migration
    class NotSupported < Reins::Error; end

    SUPPORTED_TYPES = {
      string: "VARCHAR(255)",
      text: "TEXT",
      integer: "INTEGER",
      float: "FLOAT",
      boolean: "BOOLEAN",
      datetime: "DATETIME"
    }.freeze

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
      execute(td.to_sql)
      td.indexes.each { |args| add_index(*args) }
    end

    def drop_table(name)
      return record_op(:drop_table, name) if @recording_mode

      execute("DROP TABLE #{name}")
    end

    def add_column(table, name, type, **)
      return record_op(:add_column, table, name) if @recording_mode

      execute("ALTER TABLE #{table} ADD COLUMN #{name} #{sql_type_for(type)}")
    end

    def remove_column(table, name)
      return record_op(:remove_column, table, name) if @recording_mode

      execute("ALTER TABLE #{table} DROP COLUMN #{name}")
    end

    def add_index(table, columns, unique: false, name: nil)
      return record_op(:add_index, table, columns) if @recording_mode

      cols = Array(columns)
      index_name = name || "index_#{table}_on_#{cols.join('_')}"
      execute("CREATE #{'UNIQUE ' if unique}INDEX #{index_name} ON #{table} (#{cols.join(', ')})")
    end

    def remove_index(table, columns_or_name)
      return record_op(:remove_index, table, columns_or_name) if @recording_mode

      index_name = if columns_or_name.is_a?(String)
                     columns_or_name
                   else
                     "index_#{table}_on_#{Array(columns_or_name).join('_')}"
                   end
      execute("DROP INDEX #{index_name}")
    end

    def rename_column(table, old_name, new_name)
      return record_op(:rename_column, table, old_name, new_name) if @recording_mode

      execute("ALTER TABLE #{table} RENAME COLUMN #{old_name} TO #{new_name}")
    end

    def change_column(_table, _name, _type, **)
      raise NotSupported,
            "change_column is not supported in SQLite — define explicit up/down with table copy"
    end

    private

    def execute(sql)
      Reins::Database.connection.execute(sql)
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

    def sql_type_for(type)
      SUPPORTED_TYPES[type.to_sym] || type.to_s.upcase
    end

    class TableDefinition
      attr_reader :indexes

      def initialize(name)
        @name = name
        @columns = ["id INTEGER PRIMARY KEY AUTOINCREMENT"]
        @indexes = []
      end

      Reins::Migration::SUPPORTED_TYPES.each_key do |type|
        define_method(type) do |column_name, **|
          column(column_name, type)
        end
      end

      def column(column_name, type)
        @columns << "#{column_name} #{Reins::Migration::SUPPORTED_TYPES[type.to_sym] || type.to_s.upcase}"
      end

      def timestamps
        column(:created_at, :datetime)
        column(:updated_at, :datetime)
      end

      def references(name)
        column("#{name}_id", :integer)
        @indexes << [@name, "#{name}_id"]
      end

      def to_sql
        "CREATE TABLE #{@name} (#{@columns.join(', ')})"
      end
    end
  end
end
