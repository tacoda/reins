module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins console` — boots the app and starts IRB.
        # File loading uses `Kernel#load` (not the FileSystem port) because
        # the goal is to evaluate Ruby into the current process, not read
        # bytes.
        class Console
          def initialize(file_system:, irb: ::IRB)
            @file_system = file_system
            @irb = irb
          end

          def run
            raise "config/application.rb not found in #{Dir.pwd}" unless @file_system.exist?("config/application.rb")

            load "config/application.rb"
            Reins::Application.subclasses.last&.new
            load "config/routes.rb" if @file_system.exist?("config/routes.rb")

            require "irb"
            @irb.start
          end
        end
      end
    end
  end
end
