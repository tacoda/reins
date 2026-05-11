require "reins/port"

module Reins
  module Ports
    module Driven
      # Driven port. Binds a Rack app to an address and serves until stopped.
      # Default adapter: Reins::Adapters::Driven::Puma::Server.
      module Server
        extend Reins::Port

        direction :driven

        contract  start: 1,
                  stop: 0
      end
    end
  end
end
