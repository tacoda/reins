require "reins/generators/app_generator"

module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins new NAME` — scaffolds a runnable app via
        # the AppGenerator, writing through the supplied FileSystem-port
        # adapter.
        class New
          def initialize(file_system:)
            @file_system = file_system
          end

          def run(name)
            Reins::Generators::AppGenerator.new(name).run(file_system: @file_system)
          end
        end
      end
    end
  end
end
