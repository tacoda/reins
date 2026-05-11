module Reins
  module Ports
    module Driven
      # Driven port. The core never calls Time.now directly — timestamps come
      # through this port so tests can substitute a fixed clock.
      module Clock
        CONTRACT = {
          now: 0
        }.freeze
      end
    end
  end
end
