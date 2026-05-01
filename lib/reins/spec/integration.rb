require "rack/test"

module Reins
  module Spec
    module Integration
      def self.included(base)
        base.include Rack::Test::Methods
      end
    end
  end
end
