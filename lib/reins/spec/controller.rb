require "rack/test"

module Reins
  module Spec
    module Controller
      def self.included(base)
        base.include Rack::Test::Methods
      end
    end
  end
end
