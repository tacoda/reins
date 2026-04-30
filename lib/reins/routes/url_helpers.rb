module Reins
  module Routes
    # Single shared module mixed into Reins::Controller and Reins::View.
    # Methods are added by the DSL at route declaration time, removed on
    # `reset!` (called by `Application#route` so each fresh app has a clean
    # helper namespace).
    #
    # One process is expected to host one Reins::Application; running two
    # in the same process will overwrite each other's helpers.
    module UrlHelpers
      class << self
        def reset!
          instance_methods(false).each { |m| remove_method(m) }
        end

        def define_for(rule)
          return unless rule.name

          name = rule.name.to_s
          pattern = rule.pattern
          vars = rule.vars

          define_path_method("#{name}_path", pattern, vars)
          define_url_method("#{name}_url", pattern, vars)
        end

        def expand_path(pattern, vars, args, opts)
          values = extract_values(vars, args, opts)
          path = pattern.dup
          vars.each do |var|
            value = values[var.to_s] || values[var.to_sym]
            raise ArgumentError, "missing value for :#{var}" if value.nil?

            path = path.sub(":#{var}", value.to_s)
          end
          path
        end

        private

        def define_path_method(method_name, pattern, vars)
          define_method(method_name) do |*args, **opts|
            UrlHelpers.expand_path(pattern, vars, args, opts)
          end
        end

        def define_url_method(method_name, pattern, vars)
          define_method(method_name) do |*args, **opts|
            host = opts.delete(:host) || raise(ArgumentError, "host: required for *_url helper")
            scheme = opts.delete(:scheme) || "http"
            "#{scheme}://#{host}#{UrlHelpers.expand_path(pattern, vars, args, opts)}"
          end
        end

        def extract_values(vars, args, opts)
          return args[0] if args.size == 1 && args[0].is_a?(Hash)
          return opts if args.empty? && !opts.empty?

          vars.zip(args).to_h
        end
      end
    end
  end
end
