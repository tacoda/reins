require "reins/port"

module Reins
  module Ports
    module Driving
      # Driving port. The outside world hands a Reins::Core::Http::Request to
      # the application and receives a Reins::Core::Http::Response.
      #
      # Implemented by the core action dispatcher. Driven by adapters such as
      # Reins::Adapters::Driving::Rack::App.
      module HttpApp
        extend Reins::Port

        direction :driving

        contract call: 1
      end
    end
  end
end
