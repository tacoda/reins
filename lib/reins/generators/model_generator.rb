require "reins/core/generators/blueprint"
require "reins/core/generators/blueprint_writer"
require "reins/adapters/driven/filesystem/real"

module Reins
  module Generators
    class ModelGenerator
      def initialize(name, fields = [])
        @name = name
        @fields = fields.map { |f| f.split(":", 2) }
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

      def blueprint
        bp = Reins::Core::Generators::Blueprint.new
        bp.add_file("app/models/#{model_file_basename}.rb", model_content)
        bp.add_file(migration_path, migration_content)
        bp.add_file("spec/models/#{model_file_basename}_spec.rb", spec_content)
        bp
      end

      def run(file_system: Reins::Adapters::Driven::Filesystem::Real.new)
        Reins::Core::Generators::BlueprintWriter.new(file_system).write(blueprint)
      end

      private

      def model_content
        "class #{model_class_name} < ApplicationRecord\nend\n"
      end

      def migration_path
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        "db/migrate/#{timestamp}_create_#{table_name}.rb"
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

      def spec_content
        <<~RUBY
          require "spec_helper"

          RSpec.describe #{model_class_name}, type: :model do
            it "is a Reins::Model::Base subclass" do
              expect(#{model_class_name}.ancestors).to include(Reins::Model::Base)
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
