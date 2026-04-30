module Reins
  # One-shot flash messages, persisted via the Rack session.
  #
  # `flash[k] = v` is readable on the *next* request and cleared after it.
  # `flash.now[k] = v` is readable on the *current* request only.
  class Flash
    SESSION_KEY = "_flash".freeze

    def initialize(session)
      @session = session
      @inbound = (session[SESSION_KEY] || {}).dup
      @outbound = {}
      @now_store = {}
    end

    def [](key)
      key = key.to_s
      return @now_store[key] if @now_store.key?(key)

      @inbound[key]
    end

    def []=(key, value)
      @outbound[key.to_s] = value
    end

    def now
      @now ||= NowProxy.new(@now_store)
    end

    def sweep!
      if @outbound.empty?
        @session.delete(SESSION_KEY)
      else
        @session[SESSION_KEY] = @outbound
      end
    end

    class NowProxy
      def initialize(store)
        @store = store
      end

      def [](key) = @store[key.to_s]

      def []=(key, value)
        @store[key.to_s] = value
      end
    end
  end
end
