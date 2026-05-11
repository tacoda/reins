require "reins/model/errors"
require "reins/model/schema"
require "reins/model/relation"
require "reins/model/persistence"
require "reins/model/validations"
require "reins/model/callbacks"
require "reins/model/associations"
require "reins/adapters/driven/sqlite/repository"
require "reins/adapters/driven/sqlite/schema_inspector"

module Reins
  module Model
    class Base
      include Schema
      include Callbacks
      include Validations
      include Persistence
      include Associations

      class << self
        attr_writer :table_name, :repository, :schema_inspector

        def repository
          @repository ||= Reins::Adapters::Driven::Sqlite::Repository.new(Reins::Database.connection)
        end

        def schema_inspector
          @schema_inspector ||= Reins::Adapters::Driven::Sqlite::SchemaInspector.new(Reins::Database.connection)
        end

        def reset_adapters!
          @repository = nil
          @schema_inspector = nil
        end

        def table_name
          @table_name ||= compute_table_name
        end

        def primary_key
          "id"
        end

        def all
          Relation.new(self)
        end

        def where(*, &) = all.where(*, &)
        def order(*)    = all.order(*)
        def limit(value)    = all.limit(value)
        def offset(value)   = all.offset(value)
        def count           = all.count
        def pluck(field)    = all.pluck(field)
        def first           = all.first
        def last            = all.last

        private

        def compute_table_name
          if name
            pluralize(Reins.to_underscore(name.split("::").last))
          elsif superclass.respond_to?(:table_name)
            superclass.table_name
          else
            raise "anonymous Reins::Model class needs `self.table_name = ...`"
          end
        end

        def pluralize(str)
          if str.end_with?("y") && !str.end_with?(*%w[ay ey iy oy uy])
            "#{str[0..-2]}ies"
          else
            "#{str}s"
          end
        end
      end

      def initialize(attrs = {})
        @attributes = {}
        @persisted = false
        attrs.each { |k, v| @attributes[k.to_s] = v }
        run_callbacks(:after_initialize)
      end

      def [](name)
        @attributes[name.to_s]
      end

      def []=(name, value)
        @attributes[name.to_s] = value
      end

      def id
        @attributes[self.class.primary_key]
      end

      def ==(other)
        other.is_a?(self.class) && id && id == other.id
      end

      def respond_to_missing?(name, include_private = false)
        attr = name.to_s.chomp("=")
        self.class.column_names.include?(attr) || super
      end

      def method_missing(name, *args)
        attr = name.to_s.chomp("=")
        return super unless self.class.column_names.include?(attr)

        if name.to_s.end_with?("=")
          @attributes[attr] = args[0]
        else
          self.class.cast(attr, @attributes[attr])
        end
      end
    end
  end
end
