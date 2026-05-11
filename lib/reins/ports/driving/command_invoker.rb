require "reins/port"

module Reins
  module Ports
    module Driving
      # Driving port. The outside world invokes a named command with positional
      # and keyword arguments. The core dispatches to the right command object.
      #
      # Implemented by the core CLI dispatcher. Driven by adapters such as
      # Reins::Adapters::Driving::Thor::Cli.
      module CommandInvoker
        extend Reins::Port

        direction :driving

        contract invoke: -1
      end
    end
  end
end
