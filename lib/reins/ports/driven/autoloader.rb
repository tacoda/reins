require "reins/port"

module Reins
  module Ports
    module Driven
      # Driven port. Bootstraps a constant autoloader for the app's source
      # tree. Reins::Application asks for `setup(paths)` at boot, `eager_load!`
      # when configured for it, and `reload!` from the dev reload middleware.
      # The core never references Zeitwerk directly — the adapter does.
      module Autoloader
        extend Reins::Port

        direction :driven

        contract  setup: 1,
                  eager_load!: 0,
                  reload!: 0,
                  reset!: 0
      end
    end
  end
end
