require "reins/core/generators/blueprint"
require "reins/core/generators/blueprint_writer"
require "reins/adapters/driven/filesystem/real"

module Reins
  module Generators
    class ControllerGenerator
      def initialize(name, actions = [])
        @name = name
        @actions = actions
      end

      def blueprint
        bp = Reins::Core::Generators::Blueprint.new
        bp.add_file("app/controllers/#{file_basename}_controller.rb", controller_content)
        @actions.each do |action|
          bp.add_file("app/views/#{file_basename}/#{action}.html.erb", "")
        end
        bp.add_file("spec/controllers/#{file_basename}_controller_spec.rb", spec_content)
        bp
      end

      def run(file_system: Reins::Adapters::Driven::Filesystem::Real.new)
        Reins::Core::Generators::BlueprintWriter.new(file_system).write(blueprint)
      end

      private

      def controller_class
        "#{class_chunk(@name)}Controller"
      end

      def file_basename
        Reins.to_underscore(class_chunk(@name))
      end

      def class_chunk(name)
        name.split("_").map(&:capitalize).join
      end

      def controller_content
        methods = @actions.map { |a| "  def #{a}\n  end" }.join("\n\n")
        body = methods.empty? ? "" : "\n#{methods}\n"
        <<~RUBY
          class #{controller_class} < ApplicationController#{body}
          end
        RUBY
      end

      def spec_content
        <<~RUBY
          require "spec_helper"

          RSpec.describe #{controller_class}, type: :controller do
            # Add specs for each action.
          end
        RUBY
      end
    end
  end
end
