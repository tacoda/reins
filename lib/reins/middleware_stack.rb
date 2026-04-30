module Reins
  class MiddlewareStack
    include Enumerable

    def initialize
      @entries = []
    end

    def use(klass, *args, &block)
      @entries << [klass, args, block]
      self
    end

    def insert_before(target, klass, *args, &block)
      idx = index_of(target)
      @entries.insert(idx, [klass, args, block])
      self
    end

    def insert_after(target, klass, *args, &block)
      idx = index_of(target)
      @entries.insert(idx + 1, [klass, args, block])
      self
    end

    def delete(klass)
      @entries.reject! { |entry| entry[0] == klass }
      self
    end

    def each(&) = @entries.each(&)

    def to_a = @entries.dup

    def include?(klass)
      @entries.any? { |entry| entry[0] == klass }
    end

    private

    def index_of(target)
      idx = @entries.index { |entry| entry[0] == target }
      raise ArgumentError, "middleware not found: #{target}" if idx.nil?

      idx
    end
  end
end
