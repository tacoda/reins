require "reins/ports/driven/process_runner"

module Reins
  module Adapters
    module Driven
      module Memory
        # In-memory implementation of the ProcessRunner port. Records every
        # call without executing. Constructed with an optional return value
        # (default true). Useful for testing CLI commands without actually
        # spawning subprocesses.
        class ProcessRunner
          include Reins::Ports::Driven::ProcessRunner

          attr_reader :calls

          def initialize(return_value: true)
            @return_value = return_value
            @calls = []
          end

          def system(*argv)
            @calls << argv
            @return_value
          end
        end
      end
    end
  end
end
