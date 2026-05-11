require "reins/adapters/driving/thor/cli"

module Reins
  # Backward-compatible handle for the Thor-driven CLI. The actual command
  # surface is Reins::Adapters::Driving::Thor::Cli; this alias exists so
  # `Reins::Cli.start(argv)` keeps working for tests and bin/reins.
  Cli = Reins::Adapters::Driving::Thor::Cli
end
