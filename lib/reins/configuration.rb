require "reins/middleware_stack"

module Reins
  class Configuration
    attr_accessor :eager_load, :reload_classes, :log_level, :log_path
    attr_reader :middleware

    DEFAULTS = {
      "development" => { eager_load: false, reload_classes: true, log_level: :debug },
      "test" => { eager_load: false, reload_classes: false, log_level: :warn },
      "production" => { eager_load: true,  reload_classes: false, log_level: :info }
    }.freeze

    def initialize(env)
      env_defaults = DEFAULTS[env.to_s] || DEFAULTS["development"]
      @eager_load     = env_defaults[:eager_load]
      @reload_classes = env_defaults[:reload_classes]
      @log_level      = env_defaults[:log_level]
      @log_path       = "log/#{env}.log"
      @middleware     = MiddlewareStack.new
      install_default_middleware
    end

    private

    def install_default_middleware
      @middleware.use Rack::ContentLength
      @middleware.use Rack::Head
    end
  end
end
