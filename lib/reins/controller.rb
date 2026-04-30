require 'rack'
require "reins/view"
require "reins/routes/url_helpers"

module Reins
  class Controller
    include Reins::Routes::UrlHelpers

    def initialize(env)
      @env = env
      @routing_params = {}
    end

    def dispatch(action, routing_params = {})
      @routing_params = routing_params
      text = send(action)
      r = get_response
      if r
        [r.status, r.headers, [r.body].flatten]
      else
        [200, { 'content-type' => 'text/html' },
         [text].flatten]
      end
    end

    def self.action(act, rp = {})
      proc { |e| new(e).dispatch(act, rp) }
    end

    attr_reader :env

    def request
      @request ||= Rack::Request.new(@env)
    end

    def params
      request.params.merge @routing_params
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

    def instance_hash
      h = {}
      instance_variables.each do |i|
        h[i] = instance_variable_get i
      end
      h
    end

    def render(view_name, _locals = {})
      filename = File.join "app", "views",
                           controller_name, "#{view_name}.html.erb"
      template = File.read filename
      v = View.new
      v.set_vars instance_hash
      v.evaluate template
      # instance_vars = instance_variables.each_with_object({}) do |var, hash|
      #   hash[var.to_s.delete("@").to_sym] = instance_variable_get(var)
      # end
      # eruby = Erubis::Eruby.new(template)
      # result = eruby.result locals.merge(instance_vars) # locals.merge(:env => env)
      # response(result)
    end
  end
end
