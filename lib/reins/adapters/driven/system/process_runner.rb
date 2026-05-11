require "reins/ports/driven/process_runner"

module Reins
  module Adapters
    module Driven
      module System
        # Default implementation of the ProcessRunner port — delegates to
        # Kernel#system. Used by `reins test` and any other shell-out the
        # framework needs.
        class ProcessRunner
          include Reins::Ports::Driven::ProcessRunner

          def system(*argv)
            Kernel.system(*argv)
          end
        end
      end
    end
  end
end
