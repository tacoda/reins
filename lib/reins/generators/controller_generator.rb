require "fileutils"

module Reins
  module Generators
    class ControllerGenerator
      def initialize(name, actions = [])
        @name = name
        @actions = actions
      end

      def run
        write_controller
        @actions.each { |action| write_view(action) }
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

      def write_controller
        path = "app/controllers/#{file_basename}_controller.rb"
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, controller_content)
      end

      def controller_content
        methods = @actions.map { |a| "  def #{a}\n  end" }.join("\n\n")
        body = methods.empty? ? "" : "\n#{methods}\n"
        <<~RUBY
          class #{controller_class} < ApplicationController#{body}
          end
        RUBY
      end

      def write_view(action)
        path = "app/views/#{file_basename}/#{action}.html.erb"
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "")
      end
    end
  end
end
