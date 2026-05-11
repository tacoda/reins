require "reins/ports/driven/autoloader"

module Reins
  module Adapters
    module Driven
      module Noop
        # No-op implementation of the Autoloader port. Used in tests that
        # don't want a real autoloader running, and as the safe fallback when
        # the application boots without any paths to autoload. Records calls
        # for assertions but does nothing.
        class Autoloader
          include Reins::Ports::Driven::Autoloader

          attr_reader :setup_paths

          def initialize
            @setup_paths = []
            @eager_loaded = false
            @reloaded = false
          end

          def setup(paths)
            @setup_paths = paths
          end

          def eager_load!
            @eager_loaded = true
          end

          def reload!
            @reloaded = true
          end

          def reset!
            @setup_paths = []
            @eager_loaded = false
            @reloaded = false
          end

          def eager_loaded?
            @eager_loaded
          end

          def reloaded?
            @reloaded
          end
        end
      end
    end
  end
end
