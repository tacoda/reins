module Reins
  module Core
    module Cli
      module Commands
        # Core command that binds a Rack-compatible app to a port via the
        # Server-port adapter. The Thor adapter loads the Rack app from
        # config.ru and hands it in; this command knows nothing about Rack
        # itself.
        class Server
          def initialize(server:)
            @server = server
          end

          def run(app:, host: "0.0.0.0", port: 8000)
            @server.start(app, host: host, port: port)
          end
        end
      end
    end
  end
end
