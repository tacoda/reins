require "reins/ports/driven/env_reader"

module Reins
  module Adapters
    module Driven
      module Memory
        # In-memory implementation of the EnvReader port. Constructed with a
        # Hash; values are read from that map rather than the process ENV.
        # Useful for tests and for deterministic configuration in CI.
        class EnvReader
          include Reins::Ports::Driven::EnvReader

          def initialize(env = {})
            @env = env.transform_keys(&:to_s)
          end

          def [](name)
            @env[name.to_s]
          end

          def fetch(name, *, &)
            @env.fetch(name.to_s, *, &)
          end

          def key?(name)
            @env.key?(name.to_s)
          end
        end
      end
    end
  end
end
