require "fileutils"
require "reins/ports/driven/file_system"

module Reins
  module Adapters
    module Driven
      module Filesystem
        # Disk-backed implementation of the FileSystem port. The only place in
        # the framework that calls FileUtils / File / Dir for write operations
        # on behalf of generators.
        class Real
          include Reins::Ports::Driven::FileSystem

          def read(path)
            File.read(path)
          end

          def write(path, content)
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, content)
            self
          end

          def mkdir_p(path)
            FileUtils.mkdir_p(path)
            self
          end

          def chmod(mode, path)
            FileUtils.chmod(mode, path)
            self
          end

          def exist?(path)
            File.exist?(path)
          end

          def glob(pattern)
            Dir.glob(pattern)
          end

          def mtime(path)
            File.mtime(path)
          end

          def rm_f(path)
            FileUtils.rm_f(path)
            self
          end
        end
      end
    end
  end
end
