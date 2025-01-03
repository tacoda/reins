# frozen_string_literal: true

require "reins/version"
require "reins/array"
require "reins/routing"

module Reins
  class Application
    def call(env)
      # `echo debug > debug.txt`;
      if env['PATH_INFO'] == '/favicon.ico'
        return [404, {'content-type' => 'text/html'}, []]
      end

      klass, act = get_controller_and_action(env)
      controller = klass.new(env)
      text = controller.send(act)
      [200, {'content-type' => 'text/html'},
        [text]]
    end
  end

  class Controller
    def initialize(env)
      @env = env
    end
  
    def env
      @env
    end
  end
end

