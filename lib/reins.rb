# frozen_string_literal: true

require "reins/cli"
require "reins/version"
require "reins/array"
require "reins/util"
require "reins/dependencies"
require "reins/routes/url_helpers"
require "reins/routes/rule"
require "reins/routes/resources"
require "reins/routes/dsl"
require "reins/database"
require "reins/sqlite_model"
require "reins/controller"
require "reins/view"

module Reins
  def self.framework_root
    __dir__
  end

  class Application
    @instances = []

    class << self
      attr_reader :instances
    end

    attr_reader :routes

    def initialize
      Reins::Application.instances << self
    end

    def route(&block)
      @routes ||= Reins::Routes::DSL.new
      Reins::Routes::UrlHelpers.reset!
      @routes.instance_eval(&block)
    end

    def call(env)
      return [404, { 'content-type' => 'text/html' }, []] if env['PATH_INFO'] == '/favicon.ico'

      begin
        verb = env['REQUEST_METHOD'].downcase.to_sym
        path = env['PATH_INFO']
        result = @routes&.check(verb, path)
        return not_found if result.nil?

        result.call(env)
      rescue StandardError
        server_error
      end
    end

    private

    def not_found
      [404, { 'content-type' => 'text/html' }, ['Not Found']]
    end

    def server_error
      body = File.exist?('public/500.html') ? File.read('public/500.html') : 'Server Error'
      [500, { 'content-type' => 'text/html' }, [body]]
    end
  end
end
