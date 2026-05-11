require "rack"
require "reins/core/http/request"
require "reins/core/http/response"

module Reins
  module Adapters
    module Driving
      module Rack
        # Driving adapter for Rack. Wraps a Rack-compatible callable (the
        # Reins::Application itself, today) and exposes the same `call(env)`
        # interface back to Rack. Also provides translators between Rack env
        # and Reins::Core::Http::Request / Response — these are how core code
        # will read requests and emit responses without ever touching Rack
        # types directly.
        class App
          def initialize(target)
            @target = target
          end

          def call(env)
            @target.call(env)
          end

          def self.translate_request(env)
            rack_request = ::Rack::Request.new(env)
            Reins::Core::Http::Request.new(
              verb: env["REQUEST_METHOD"],
              path: env["PATH_INFO"],
              params: rack_request.params,
              headers: extract_headers(env),
              body: rack_request.body.respond_to?(:read) ? rack_request.body.read : "",
              env: env
            )
          end

          def self.translate_response(response)
            body = response.body.is_a?(Array) ? response.body : [response.body]
            [response.status, response.headers, body]
          end

          def self.extract_headers(env)
            headers = {}
            headers["Content-Type"] = env["CONTENT_TYPE"] if env["CONTENT_TYPE"]
            headers["Content-Length"] = env["CONTENT_LENGTH"] if env["CONTENT_LENGTH"]
            env.each do |key, value|
              next unless key.is_a?(String) && key.start_with?("HTTP_")

              header_name = key.sub("HTTP_", "").split("_").map(&:capitalize).join("-")
              headers[header_name] = value
            end
            headers
          end
        end
      end
    end
  end
end
