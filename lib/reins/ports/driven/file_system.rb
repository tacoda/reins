module Reins
  module Ports
    module Driven
      # Driven port. The only place core code is allowed to touch the
      # filesystem. Generators emit blueprints; this port writes them.
      module FileSystem
        CONTRACT = {
          read: 1,
          write: 2,
          mkdir_p: 1,
          chmod: 2,
          exist?: 1,
          glob: 1,
          mtime: 1,
          rm_f: 1
        }.freeze
      end
    end
  end
end
