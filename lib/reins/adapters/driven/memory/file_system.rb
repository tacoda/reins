require "reins/ports/driven/file_system"

module Reins
  module Adapters
    module Driven
      module Memory
        # In-memory implementation of the FileSystem port. Used to unit-test
        # generators and any other core code that writes files, without
        # touching disk.
        class FileSystem
          include Reins::Ports::Driven::FileSystem

          def initialize
            @entries = {}
            @executables = {}
            @mtimes = {}
          end

          def read(path)
            raise Errno::ENOENT, path unless @entries.key?(path)

            @entries[path]
          end

          def write(path, content)
            @entries[path] = content
            @mtimes[path] = Time.now
            self
          end

          def mkdir_p(_path)
            self
          end

          def chmod(mode, path)
            @executables[path] = true if mode.to_s.include?("+x") || mode == 0o755 || mode == 0o775
            self
          end

          def exist?(path)
            @entries.key?(path)
          end

          def executable?(path)
            @executables[path] == true
          end

          def glob(pattern)
            regex = pattern_to_regex(pattern)
            @entries.keys.grep(regex)
          end

          def mtime(path)
            raise Errno::ENOENT, path unless @mtimes.key?(path)

            @mtimes[path]
          end

          def rm_f(path)
            @entries.delete(path)
            @executables.delete(path)
            @mtimes.delete(path)
            self
          end

          private

          def pattern_to_regex(pattern)
            escaped = Regexp.escape(pattern)
            escaped = escaped.gsub('\*\*', ".*").gsub('\*', "[^/]*").gsub('\?', ".")
            Regexp.new("\\A#{escaped}\\z")
          end
        end
      end
    end
  end
end
