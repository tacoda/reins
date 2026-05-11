module Reins
  module Ports
    module Driven
      # Driven port. Binds a Rack app to an address and serves until stopped.
      # Default adapter: Reins::Adapters::Driven::Puma::Server.
      module Server
        CONTRACT = {
          start: 1,
          stop: 0
        }.freeze
      end
    end
  end
end
