module Reins
  module Core
    module Generators
      # Pure value object describing a set of files to be written and a set of
      # paths to be marked executable. Generators return a Blueprint; the
      # blueprint is then handed to a FileSystem-port adapter that writes it.
      class Blueprint
        attr_reader :files, :executables

        def initialize
          @files = []
          @executables = []
        end

        def add_file(path, content)
          @files << [path, content]
          self
        end

        def add_executable(path)
          @executables << path
          self
        end

        def empty?
          @files.empty? && @executables.empty?
        end

        def merge(other)
          merged = self.class.new
          (@files + other.files).each { |path, content| merged.add_file(path, content) }
          (@executables + other.executables).each { |path| merged.add_executable(path) }
          merged
        end

        def ==(other)
          other.is_a?(self.class) &&
            other.files == @files &&
            other.executables == @executables
        end
        alias eql? ==

        def hash
          [@files, @executables].hash
        end
      end
    end
  end
end
