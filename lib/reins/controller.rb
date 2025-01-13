require 'rack'
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

    def request
      @request ||= Rack::Request.new(@env)
    end

    def params
      request.params
    end

    def response(text, status = 200, headers = {})
      raise "Already responded!" if @response
      a = [text].flatten
      @response = Rack::Response.new(a, status, headers)
    end

    def get_response
      @response
    end

    def controller_name
      klass = self.class
      klass = klass.to_s.gsub(/Controller$/, "")
      Reins.to_underscore klass
    end

    def render(view_name, locals = {})
      filename = File.join "app", "views",
        controller_name, "#{view_name}.html.erb"
      template = File.read filename
      instance_vars = instance_variables.each_with_object({}) do |var, hash|
        hash[var.to_s.delete("@").to_sym] = instance_variable_get(var)
      end
      eruby = Erubis::Eruby.new(template)
      result = eruby.result locals.merge(instance_vars) # locals.merge(:env => env)
      response(result)
    end
  end
end