require "fileutils"

module Reins
  module Generators
    class ModelGenerator
      def initialize(name, fields = [])
        @name = name
        @fields = fields.map { |f| f.split(":", 2) }
      end

      def run
        write_model
        write_migration
      end

      def model_class_name
        @name.split("_").map(&:capitalize).join
      end

      def model_file_basename
        Reins.to_underscore(model_class_name)
      end

      def table_name
        pluralize(model_file_basename)
      end

      private

      def write_model
        path = "app/models/#{model_file_basename}.rb"
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "class #{model_class_name} < ApplicationRecord\nend\n")
      end

      def write_migration
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        path = "db/migrate/#{timestamp}_create_#{table_name}.rb"
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, migration_content)
      end

      def migration_content
        column_lines = @fields.map { |name, type| "      t.#{type} :#{name}" }
        column_lines << "      t.timestamps"
        <<~RUBY
          class Create#{table_name.split('_').map(&:capitalize).join} < Reins::Migration
            def change
              create_table :#{table_name} do |t|
          #{column_lines.join("\n")}
              end
            end
          end
        RUBY
      end

      def pluralize(str)
        if str.end_with?("y") && !str.end_with?("ay", "ey", "iy", "oy", "uy")
          "#{str[0..-2]}ies"
        else
          "#{str}s"
        end
      end
    end
  end
end
