module Reins
  module Ports
    module Driving
      # Driving port. The outside world hands a Reins::Core::Http::Request to
      # the application and receives a Reins::Core::Http::Response.
      #
      # Implemented by the core action dispatcher. Driven by adapters such as
      # Reins::Adapters::Driving::Rack::App.
      module HttpApp
        CONTRACT = {
          call: 1
        }.freeze
      end
    end
  end
end
