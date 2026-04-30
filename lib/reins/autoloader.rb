require "zeitwerk"

module Reins
  module Autoloader
    @loader = nil

    class << self
      attr_reader :loader

      def setup(paths)
        return if paths.empty?

        @loader = Zeitwerk::Loader.new
        paths.each { |p| @loader.push_dir(p) if Dir.exist?(p) }
        @loader.enable_reloading if Reins.config.reload_classes
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
