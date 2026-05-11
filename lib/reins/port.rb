module Reins
  # Lightweight DSL for declaring a port. Extend a module with Reins::Port and
  # call `direction` and `contract` — the rest of the framework can then
  # discover the port, its direction, and the methods every adapter must
  # implement.
  #
  #   module Reins::Ports::Driven::Repository
  #     extend Reins::Port
  #
  #     direction :driven
  #
  #     contract  find_all: 1,
  #               insert:   2,
  #               update:   4
  #   end
  #
  # The module ends up with `DIRECTION` and `CONTRACT` constants (frozen),
  # responds to `#port?` and `#direction`, and is registered in
  # `Reins::Port.all` / `.driven` / `.driving`.
  module Port
    VALID_DIRECTIONS = %i[driven driving].freeze

    @registry = []

    class << self
      def extended(base)
        base.instance_variable_set(:@reins_direction, nil)
        base.instance_variable_set(:@reins_contract, nil)
        @registry << base
      end

      # Registered, *named* ports only. Anonymous modules that extend
      # Reins::Port (e.g. test fixtures) are filtered out so they don't
      # pollute introspection done by the application or generators.
      def all
        @registry.select(&:name)
      end

      def driven
        all.select { |p| p.direction == :driven }
      end

      def driving
        all.select { |p| p.direction == :driving }
      end

      def reset!
        @registry = []
      end
    end

    def port?
      true
    end

    # Conventional adapter slot name for this port — derived from the const
    # name. SchemaInspector → :schema_inspector. Used by Application to map
    # a port to the adapter key in its adapter graph.
    def adapter_key
      Reins.to_underscore(name.split("::").last).to_sym
    end

    def direction(value = nil)
      return @reins_direction if value.nil?

      raise "direction already set on #{self}: #{@reins_direction}" if @reins_direction
      unless VALID_DIRECTIONS.include?(value)
        raise ArgumentError,
              "unknown direction #{value.inspect} on #{self}; expected one of #{VALID_DIRECTIONS.inspect} " \
              "(driven or driving)"
      end

      @reins_direction = value
      const_set(:DIRECTION, value)
      value
    end

    def contract(methods)
      raise "direction must be set before contract on #{self}" unless @reins_direction
      raise "contract already declared on #{self}" if @reins_contract

      methods.each do |name, arity|
        validate_method_name!(name)
        validate_method_arity!(name, arity)
      end

      @reins_contract = methods.freeze
      const_set(:CONTRACT, @reins_contract)
    end

    private

    def validate_method_name!(name)
      return if name.is_a?(Symbol)

      raise ArgumentError, "contract key must be a Symbol on #{self}: got #{name.inspect}"
    end

    def validate_method_arity!(name, arity)
      return if arity.is_a?(Integer)

      raise ArgumentError, "contract value for #{name} must be an Integer arity on #{self}: got #{arity.inspect}"
    end
  end
end
