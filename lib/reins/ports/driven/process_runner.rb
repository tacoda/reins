module Reins
  module Ports
    module Driven
      # Driven port. Runs a subprocess. The core never calls Kernel#system or
      # backticks directly — `reins test` and similar shell-outs go through
      # this port.
      module ProcessRunner
        CONTRACT = {
          system: -1
        }.freeze
      end
    end
  end
end
