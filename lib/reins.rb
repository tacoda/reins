# frozen_string_literal: true

require "reins/version"
require "reins/array"

module Reins
  class Application
    def call(env)
      `echo debug > debug.txt`;
      [200, {'content-type' => 'text/html'},
        ["Hello from Ruby on Reins!"]]
    end
  end
end
