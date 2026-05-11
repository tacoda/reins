module Reins
  module Core
    module Generators
      # Pure orchestration: takes a Blueprint and writes it through a
      # FileSystem-port adapter. The writer itself does no I/O — that lives in
      # the adapter.
      class BlueprintWriter
        def initialize(file_system)
          @fs = file_system
        end

        def write(blueprint, root: nil)
          blueprint.files.each do |path, content|
            @fs.write(join(root, path), content)
          end
          blueprint.executables.each do |path|
            @fs.chmod("+x", join(root, path))
          end
        end

        private

        def join(root, path)
          root.nil? || root.empty? ? path : File.join(root, path)
        end
      end
    end
  end
end
