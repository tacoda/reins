module Reins
  class Error < StandardError; end
  class DoubleResponse < Error; end
  class MissingTemplate < Error; end
  class ParameterMissing < Error; end
  class SessionMiddlewareMissing < Error; end

  module Model
    class RecordNotFound < Reins::Error; end

    class RecordInvalid < Reins::Error
      attr_reader :record

      def initialize(record)
        @record = record
        super("validation failed: #{record.errors.full_messages.join(', ')}")
      end
    end
  end
end
