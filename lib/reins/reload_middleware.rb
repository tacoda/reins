module Reins
  # Polls registered autoload paths for mtime changes; on a change, asks
  # Reins::Autoloader to reload before passing the request through.
  #
  # Mounted automatically when Reins.config.reload_classes is true.
  class ReloadMiddleware
    def initialize(app, paths)
      @app = app
      @paths = paths
      @last_check = newest_mtime
    end

    def call(env)
      current = newest_mtime
      if current && @last_check && current > @last_check
        Reins::Autoloader.reload!
        @last_check = current
      end
      @app.call(env)
    end

    private

    def newest_mtime
      @paths.flat_map { |path| Dir.glob("#{path}/**/*.rb") }
            .map { |f| File.mtime(f) }
            .max
    end
  end
end
