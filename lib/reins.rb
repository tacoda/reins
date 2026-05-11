# frozen_string_literal: true

require "rack"
require "reins/cli"
require "reins/version"
require "reins/ports"
require "reins/core"
require "reins/adapters"
require "reins/array"
require "reins/util"
require "reins/env"
require "reins/configuration"
require "reins/middleware_stack"
require "reins/logger"
require "reins/autoloader"
require "reins/reload_middleware"
require "reins/errors"
require "reins/parameters"
require "reins/flash"
require "reins/routes/url_helpers"
require "reins/routes/rule"
require "reins/routes/resources"
require "reins/routes/dsl"
require "reins/database"
require "reins/database_config"
require "reins/migration"
require "reins/migrator"
require "reins/schema"
require "reins/model/base"
require "reins/controller"
require "reins/generators"
require "reins/view"

module Reins
  def self.framework_root
    __dir__
  end

  def self.env
    @env = nil unless @env_seen == ENV.fetch("REINS_ENV", nil)
    @env_seen = ENV.fetch("REINS_ENV", nil)
    @env ||= Env.new(ENV["REINS_ENV"] || "development")
  end

  def self.config
    @config ||= Configuration.new(env)
  end

  def self.configure
    yield config
    config
  end

  def self.reset_config!
    @config = nil
  end

  def self.logger
    @logger ||= LoggerFactory.build(path: config.log_path, level: config.log_level)
  end

  def self.reset_logger!
    @logger = nil
  end

  def self.application
    raise "no Reins::Application has been constructed" if Application.instances.empty?

    Application.instances.last
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

    def route(&)
      @routes ||= Reins::Routes::DSL.new
      Reins::Routes::UrlHelpers.reset!
      @routes.instance_eval(&)
    end

    def call(env)
      @rack_app ||= build_rack_app
      @rack_app.call(env)
    end

    def dispatch_request(env)
      return [404, { 'content-type' => 'text/html' }, []] if env['PATH_INFO'] == '/favicon.ico'

      verb = env['REQUEST_METHOD'].downcase.to_sym
      path = env['PATH_INFO']
      result = @routes&.check(verb, path)
      return not_found if result.nil?

      begin
        result.call(env)
      rescue Reins::Error
        raise
      rescue StandardError
        server_error
      end
    end

    private

    def build_rack_app
      app = method(:dispatch_request)
      builder = Rack::Builder.new
      Reins.config.middleware.each do |klass, args, block|
        builder.use(klass, *args, &block)
      end
      builder.run(app)
      builder.to_app
    end

    def not_found
      [404, { 'content-type' => 'text/html' }, ['Not Found']]
    end

    def server_error
      body = File.exist?('public/500.html') ? File.read('public/500.html') : 'Server Error'
      [500, { 'content-type' => 'text/html' }, [body]]
    end
  end
end
