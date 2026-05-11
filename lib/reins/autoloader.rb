require "reins/adapters/driven/zeitwerk/autoloader"

module Reins
  # Public-API facade for the Autoloader port. Defaults to the Zeitwerk
  # adapter; tests can swap in Noop::Autoloader (or any other implementation
  # of Ports::Driven::Autoloader) via Reins::Autoloader.adapter = ...
  module Autoloader
    class << self
      def adapter
        @adapter ||= Reins::Adapters::Driven::Zeitwerk::Autoloader.new(
          reload_classes: Reins.config.reload_classes
        )
      end

      attr_writer :adapter

      def setup(paths)
        adapter.setup(paths)
      end

      def eager_load!
        adapter.eager_load!
      end

      def reload!
        adapter.reload!
      end

      def reset!
        adapter.reset!
        @adapter = nil
      end

      # Internal — used by tests that bypass the public Reins::Autoloader
      # facade and inspect the underlying loader.
      def loader
        adapter.instance_variable_get(:@loader)
      end
    end
  end
end
