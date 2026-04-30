require "sqlite3"

module Reins
  class Database
    DEFAULT_PATH = "test.db".freeze

    class << self
      attr_writer :path

      def path
        @path ||= DEFAULT_PATH
      end

      def connection
        @connection ||= SQLite3::Database.new(path)
      end

      def reset!
        @connection&.close
        @connection = nil
        @path = nil
      end
    end
  end
end
