require "reins/ports/driven/clock"

module Reins
  module Adapters
    module Driven
      module Memory
        # Fixed-clock implementation of the Clock port. Constructed with a
        # Time; #now returns that value. Useful for tests that need
        # deterministic timestamps.
        class Clock
          include Reins::Ports::Driven::Clock

          def initialize(time = Time.at(0).utc)
            @time = time
          end

          def now
            @time
          end

          def advance!(seconds)
            @time += seconds
          end
        end
      end
    end
  end
end
