require "reins/ports/driven/clock"

module Reins
  module Adapters
    module Driven
      module System
        # Default implementation of the Clock port. Reads Time.now. The core
        # never calls Time.now directly — timestamps come through this port
        # so tests can substitute a fixed clock (see Memory::Clock).
        class Clock
          include Reins::Ports::Driven::Clock

          def now
            Time.now
          end
        end
      end
    end
  end
end
