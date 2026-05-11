require "puma"
require "reins/ports/driven/server"

module Reins
  module Adapters
    module Driven
      module Puma
        # Puma implementation of the Server port. Binds a Rack-compatible app
        # to a TCP listener and runs until stopped. Trapping SIGINT for a
        # graceful stop is handled here, not in the core CLI command.
        class Server
          include Reins::Ports::Driven::Server

          def initialize
            @server = nil
          end

          def start(app, host: "0.0.0.0", port: 8000)
            @server = ::Puma::Server.new(app)
            @server.add_tcp_listener(host, port)
            trap("INT") do
              stop
              puts "\nServer stopped."
              exit
            end
            puts "Serving on http://#{host == '0.0.0.0' ? 'localhost' : host}:#{port}"
            @server.run.join
          end

          def stop
            @server&.stop
            @server = nil
          end
        end
      end
    end
  end
end
