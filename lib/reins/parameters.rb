require "reins/errors"

module Reins
  class Parameters
    def initialize(hash = {})
      @hash = hash.transform_keys(&:to_s)
    end

    def require(key)
      value = @hash[key.to_s]
      raise ParameterMissing, "param is missing or the value is empty: #{key}" if blank?(value)

      wrap(value)
    end

    def permit(*keys)
      allowed = keys.map(&:to_s)
      Parameters.new(@hash.slice(*allowed))
    end

    def [](key)
      wrap(@hash[key.to_s])
    end

    def []=(key, value)
      @hash[key.to_s] = value
    end

    def merge(other)
      other_hash = other.respond_to?(:to_h) ? other.to_h : other
      Parameters.new(@hash.merge(other_hash.transform_keys(&:to_s)))
    end

    def to_h
      @hash.dup
    end
    alias to_hash to_h

    def key?(key) = @hash.key?(key.to_s)
    def keys = @hash.keys
    def each(&) = @hash.each(&)
    def empty? = @hash.empty?

    private

    def wrap(value)
      value.is_a?(Hash) ? Parameters.new(value) : value
    end

    def blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end
  end
end
