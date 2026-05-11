require "reins/port"

module Reins
  module Ports
    module Driven
      # Driven port. Runs a subprocess. The core never calls Kernel#system or
      # backticks directly — `reins test` and similar shell-outs go through
      # this port.
      module ProcessRunner
        extend Reins::Port

        direction :driven

        contract system: -1
      end
    end
  end
end
