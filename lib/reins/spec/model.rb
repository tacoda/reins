require "reins/database"

module Reins
  module Spec
    module Model
      class Rollback < StandardError; end

      def self.included(base)
        base.around do |example|
          Reins::Spec::Model.in_transaction { example.run }
        end
      end

      def self.in_transaction
        Reins::Database.connection.transaction do
          yield
          raise Rollback
        end
      rescue Rollback
        # Caught — the transaction has rolled back.
      end
    end
  end
end
