require "reins/profile"

module Reins
  # Translates a Hash of adapter declarations into a wired adapter map.
  #
  # The Hash can come from anywhere — a profile, a Ruby config file
  # (e.g. config/adapters.rb whose last expression is a Hash), an inline
  # block. Each value can be:
  #
  #   * an instance      — stored as-is
  #   * a Class          — instantiated with no-arg .new
  #   * a Proc/lambda    — called lazily; the result is stored
  #
  # Apply merges into the target map; later applies override earlier ones.
  class Configurator
    def initialize(target)
      @target = target
    end

    def apply(declarations)
      declarations.each do |key, declaration|
        @target[key] = resolve(declaration)
      end
      @target
    end

    def load(path)
      content = File.read(path)
      result = eval(content, binding, path) # rubocop:disable Security/Eval
      raise ArgumentError, "#{path} must return a Hash; got #{result.class}" unless result.is_a?(Hash)

      apply(result)
    end

    def self.from_profile(name, into:)
      profile = Reins::Profile.fetch(name)
      new(into).apply(profile[:adapters])
    end

    private

    def resolve(declaration)
      case declaration
      when Proc then declaration.call
      when Class then declaration.new
      else declaration
      end
    end
  end
end
