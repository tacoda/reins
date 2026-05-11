require "reins/core/generators/blueprint"
require "reins/util"

module Reins
  module Core
    module Generators
      # Generates testing artifacts for a port:
      #   * a "double" — a configurable test double that includes the port
      #     module and records every call. Doubles as both spy (assert on
      #     #calls) and fake (configure return values).
      #   * a "use-case spec" — a template that wires the double into
      #     Reins::Application.new(profile: :test) and demonstrates the
      #     port-call-through-the-app pattern.
      class TestGenerator
        VALID_SCOPES = %i[app lib].freeze

        def initialize(port_module:, port_module_name:, port_require:, scope: :app)
          raise ArgumentError, "unknown scope: #{scope.inspect}" unless VALID_SCOPES.include?(scope)

          @port_module = port_module
          @port_module_name = port_module_name
          @port_require = port_require
          @scope = scope
        end

        def blueprint
          bp = Blueprint.new
          bp.add_file(double_path, double_content)
          bp.add_file(use_case_path, use_case_content)
          bp
        end

        def port_basename
          @port_basename ||= short_module_name.split("_").then do |_parts|
            # input is already snake_case via to_underscore
            short_module_name
          end
        end

        def double_class_name
          "#{camelize(short_module_name)}Double"
        end

        private

        def short_module_name
          @short_module_name ||= Reins.to_underscore(@port_module_name.split("::").last)
        end

        def camelize(snake)
          snake.split("_").map(&:capitalize).join
        end

        def double_path
          base = @scope == :lib ? "spec/reins/doubles" : "spec/doubles"
          "#{base}/#{short_module_name}_double.rb"
        end

        def use_case_path
          base = @scope == :lib ? "spec/reins/use_cases" : "spec/use_cases"
          "#{base}/#{short_module_name}_use_case_spec.rb"
        end

        def double_content
          method_defs = @port_module.const_get(:CONTRACT).map do |name, arity|
            method_def(name, arity)
          end.join("\n\n")

          <<~RUBY
            require "#{@port_require}"

            class #{double_class_name}
              include #{@port_module_name}

              attr_reader :calls

              def initialize(returns: {})
                @calls = []
                @returns = returns
              end

            #{indent(method_defs, 2)}
            end
          RUBY
        end

        def use_case_content
          adapter_key = short_module_name.to_sym
          <<~RUBY
            require "spec_helper"
            require_relative "../#{double_dir_basename}/#{short_module_name}_double"

            RSpec.describe "#{double_class_name} use cases" do
              let(:double) { #{double_class_name}.new }
              let(:app) do
                Reins::Application.new(
                  profile: :test,
                  adapters: { #{adapter_key}: double },
                  validate: false
                )
              end

              it "records calls into the port through the application" do
                # Replace with the use case you're testing:
                # app.adapter(:#{adapter_key}).some_method(args)
                # expect(double.calls.first[:method]).to eq(:some_method)
              end
            end
          RUBY
        end

        def double_dir_basename
          "doubles"
        end

        def method_def(name, arity)
          params = stub_params(arity)
          method_name = name.to_s
          args_expr = params_to_args_expr(arity)
          <<~RUBY.chomp
            def #{method_name}(#{params})
              @calls << { method: :#{method_name}, args: #{args_expr} }
              @returns.fetch(:#{method_name}, nil)
            end
          RUBY
        end

        def stub_params(arity)
          if arity == -1
            "*args, **kwargs"
          elsif arity.negative?
            required = -arity - 1
            req = Array.new(required) { |i| "arg#{i}" }
            (req + ["*rest"]).join(", ")
          else
            Array.new(arity) { |i| "arg#{i}" }.join(", ")
          end
        end

        def params_to_args_expr(arity)
          if arity == -1
            "args"
          elsif arity.negative?
            "[#{(Array.new(-arity - 1) { |i| "arg#{i}" } + ['*rest']).join(', ')}]"
          else
            "[#{Array.new(arity) { |i| "arg#{i}" }.join(', ')}]"
          end
        end

        def indent(text, spaces)
          pad = " " * spaces
          text.each_line.map { |line| line.strip.empty? ? line : pad + line }.join
        end
      end
    end
  end
end
