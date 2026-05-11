require "reins/port"

module Reins
  module Ports
    module Driven
      # Driven port. The core never calls Time.now directly — timestamps come
      # through this port so tests can substitute a fixed clock.
      module Clock
        extend Reins::Port

        direction :driven

        contract now: 0
      end
    end
  end
end
