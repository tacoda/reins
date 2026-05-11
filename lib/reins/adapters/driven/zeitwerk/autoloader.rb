require "zeitwerk"
require "reins/ports/driven/autoloader"

module Reins
  module Adapters
    module Driven
      module Zeitwerk
        # Zeitwerk implementation of the Autoloader port. Wraps a
        # ::Zeitwerk::Loader so the core boot path can request setup, eager
        # loading, and reload without knowing about Zeitwerk specifically.
        class Autoloader
          include Reins::Ports::Driven::Autoloader

          def initialize(reload_classes: false)
            @reload_classes = reload_classes
            @loader = nil
          end

          def setup(paths)
            return if paths.empty?

            @loader = ::Zeitwerk::Loader.new
            paths.each { |p| @loader.push_dir(p) if Dir.exist?(p) }
            @loader.enable_reloading if @reload_classes
            @loader.setup
          end

          def eager_load!
            @loader&.eager_load
          end

          def reload!
            @loader&.reload
          end

          def reset!
            @loader&.unload
            @loader = nil
          end
        end
      end
    end
  end
end
