require 'erubis'
require "reins/file_model"

module Reins
  class Controller
    include Reins::Model

    def initialize(env)
      @env = env
    end
  
    def env
      @env
    end

    def controller_name
      klass = self.class
      klass = klass.to_s.gsub(/Controller$/, "")
      Reins.to_underscore klass
    end

    def render(view_name, locals = {})
      filename = File.join "app", "views",
        controller_name, "#{view_name}.html.erb"
      # TODO: Add instance variables to template
      template = File.read filename
      eruby = Erubis::Eruby.new(template)
      eruby.result locals.merge(:env => env)
    end
  end
end