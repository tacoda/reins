# frozen_string_literal: true

require "reins/cli"
require "reins/version"
require "reins/array"
require "reins/routing"
require "reins/util"
require "reins/dependencies"
require "reins/database"
require "reins/sqlite_model"
require "reins/controller"

module Reins
  def self.framework_root
    __dir__
  end

  class Application
    def call(env)
      # `echo debug > debug.txt`;
      return [404, { 'content-type' => 'text/html' }, []] if env['PATH_INFO'] == '/favicon.ico'

      begin
        rack_app = get_rack_app(env)
        rack_app.call(env)
      rescue StandardError
        [500, { 'content-type' => 'text/html' },
         [File.read('public/500.html')]]
      end
      # klass, act = get_controller_and_action(env)
      # controller = klass.new(env)
      # text = controller.send(act)
      # r = controller.get_response
      # if r
      #   [r.status, r.headers, [r.body].flatten]
      # else
      #   controller.render(act)
      #   r = controller.get_response
      #   [r.status, r.headers, [r.body].flatten]
      # end
      # begin
      #   text = controller.send(act)
      # rescue
      #   return [500, {'content-type' => 'text/html'},
      #     ['Server Error']]
      # end
      # [200, {'content-type' => 'text/html'},
      #   [text]]
    end
  end
end
