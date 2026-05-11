module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins test` — shells out to RSpec via the
        # ProcessRunner port. Forwarded args go straight to rspec.
        class Test
          def initialize(process_runner:)
            @process_runner = process_runner
          end

          def run(*)
            @process_runner.system("bundle", "exec", "rspec", *)
          end
        end
      end
    end
  end
end
