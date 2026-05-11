require "reins/generators/app_generator"

module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins new NAME [--slim]` — scaffolds a runnable
        # app via the AppGenerator using the named profile (default :standard),
        # writing through the supplied FileSystem-port adapter.
        class New
          def initialize(file_system:)
            @file_system = file_system
          end

          def run(name, profile: :standard)
            Reins::Generators::AppGenerator
              .new(name, profile: profile)
              .run(file_system: @file_system)
          end
        end
      end
    end
  end
end
