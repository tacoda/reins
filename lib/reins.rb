# frozen_string_literal: true

require "reins/version"
require "reins/array"
require "reins/routing"
require "reins/util"
require "reins/dependencies"
require "reins/controller"
require "reins/file_model"

module Reins
  def self.framework_root
    __dir__
  end

  class Application
    def call(env)
      # `echo debug > debug.txt`;
      if env['PATH_INFO'] == '/favicon.ico'
        return [404, {'content-type' => 'text/html'}, []]
      end

      if env['PATH_INFO'] == '/'
        return [200, {'content-type' => 'text/html'},
          ["root"]]
      end

      klass, act = get_controller_and_action(env)
      controller = klass.new(env)
      begin
        text = controller.send(act)
      rescue
        return [500, {'content-type' => 'text/html'},
          ['Server Error']]
      end
      [200, {'content-type' => 'text/html'},
        [text]]
    end
  end
end

