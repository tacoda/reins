# frozen_string_literal: true

require_relative "reins/version"

module Reins
  class Application
    def call(env)
      [200, {'content-type' => 'text/html'},
        ["Hello from Ruby on Reins!"]]
    end
  end
end
