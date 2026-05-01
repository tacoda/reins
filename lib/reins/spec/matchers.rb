require "rack"

module Reins
  module Spec
    module Matchers
      class HaveHttpStatus
        def initialize(expected)
          @expected = resolve(expected)
        end

        def matches?(response)
          @actual = response.status
          @actual == @expected
        end

        def failure_message
          "expected response to have status #{@expected}, got #{@actual}"
        end

        def failure_message_when_negated
          "expected response not to have status #{@expected}"
        end

        private

        def resolve(value)
          return value if value.is_a?(Integer)

          Rack::Utils::SYMBOL_TO_STATUS_CODE.fetch(value) do
            raise ArgumentError, "unknown status: #{value.inspect}"
          end
        end
      end

      class RedirectTo
        def initialize(url)
          @expected_url = url
        end

        def matches?(response)
          @actual_status = response.status
          location_header = response.headers["Location"] || response.headers["location"]
          @actual_location = location_header
          (300..399).cover?(@actual_status) && @actual_location == @expected_url
        end

        def failure_message
          "expected a 3xx redirect to #{@expected_url.inspect}, " \
            "got status #{@actual_status} location #{@actual_location.inspect}"
        end
      end

      # rubocop:disable Naming/PredicatePrefix
      def have_http_status(value)
        HaveHttpStatus.new(value)
      end
      # rubocop:enable Naming/PredicatePrefix

      def redirect_to(url)
        RedirectTo.new(url)
      end
    end
  end
end
