module Reins
  module Ports
    module Driven
      # Driven port. Reads process environment values. The core never touches
      # ENV directly; configuration is the one layer that reads through this
      # port and feeds resolved values into the rest of the core.
      module EnvReader
        CONTRACT = {
          :[] => 1,
          :fetch => -1,
          :key? => 1
        }.freeze
      end
    end
  end
end
