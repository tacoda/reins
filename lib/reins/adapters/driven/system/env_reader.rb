require "reins/ports/driven/env_reader"

module Reins
  module Adapters
    module Driven
      module System
        # Default implementation of the EnvReader port — reads from ENV. The
        # core never touches ENV directly; configuration is the one layer
        # that reads through this port and feeds resolved values into the
        # rest of the application.
        class EnvReader
          include Reins::Ports::Driven::EnvReader

          def [](name)
            ENV.fetch(name, nil)
          end

          def fetch(name, *, &)
            ENV.fetch(name, *, &)
          end

          def key?(name)
            ENV.key?(name)
          end
        end
      end
    end
  end
end
