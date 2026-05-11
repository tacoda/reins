module Reins
  module Core
    module Http
      # Pure value object describing an inbound HTTP request as the core sees
      # it. Driving adapters (Rack, in production) translate their native
      # representation into this; the core never reads a Rack env directly.
      class Request
        attr_reader :verb, :path, :params, :headers, :body, :env

        def initialize(verb:, path:, params: {}, headers: {}, body: "", env: {})
          @verb = normalize_verb(verb)
          @path = path
          @params = params
          @headers = headers
          @body = body
          @env = env
        end

        def ==(other)
          other.is_a?(self.class) &&
            other.verb == @verb &&
            other.path == @path &&
            other.params == @params &&
            other.headers == @headers &&
            other.body == @body &&
            other.env == @env
        end
        alias eql? ==

        def hash
          [@verb, @path, @params, @headers, @body, @env].hash
        end

        private

        def normalize_verb(verb)
          verb.to_s.downcase.to_sym
        end
      end
    end
  end
end
