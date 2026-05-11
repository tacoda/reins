module Reins
  module Core
    module Http
      # Pure value object describing an HTTP response as the core produces it.
      # Driving adapters translate this to their native shape (a Rack tuple,
      # in production). No Rack-aware helpers live here — the response is
      # plain data.
      class Response
        attr_reader :status, :headers, :body

        def initialize(status:, headers: {}, body: "")
          @status = status
          @headers = headers
          @body = body
        end

        def ==(other)
          other.is_a?(self.class) &&
            other.status == @status &&
            other.headers == @headers &&
            other.body == @body
        end
        alias eql? ==

        def hash
          [@status, @headers, @body].hash
        end
      end
    end
  end
end
