require "reins/core/generators/blueprint"
require "reins/util"

module Reins
  module Core
    module Generators
      # Generates a new adapter implementing a port.
      #
      # For :driven direction, the adapter `include`s the port module and
      # defines every method from the port's CONTRACT, each raising
      # NotImplementedError until the implementer fills it in. A contract
      # spec asserts respond_to for every method on the port.
      #
      # For :driving direction, the adapter is constructor-injected with a
      # port-implementing app and uses (does not implement) the port. The
      # generated scaffold leaves the entry-point method bodies empty —
      # driving adapters are too varied to scaffold deeper than that.
      class AdapterGenerator
        VALID_DIRECTIONS = %i[driving driven].freeze
        VALID_SCOPES = %i[app lib].freeze

        def initialize(name, port_module:, port_module_name:, port_require:,
                       direction: :driven, scope: :app, namespace: nil)
          raise ArgumentError, "unknown direction: #{direction.inspect}" unless VALID_DIRECTIONS.include?(direction)
          raise ArgumentError, "unknown scope: #{scope.inspect}" unless VALID_SCOPES.include?(scope)

          @raw_name = name
          @port_module = port_module
          @port_module_name = port_module_name
          @port_require = port_require
          @direction = direction
          @scope = scope
          @namespace = namespace
        end

        def blueprint
          bp = Blueprint.new
          bp.add_file(adapter_path, adapter_content)
          bp.add_file(spec_path, spec_content)
          bp
        end

        def file_basename
          @file_basename ||= Reins.to_underscore(@raw_name.to_s.tr("-", "_"))
        end

        def class_name
          @class_name ||= file_basename.split("_").map(&:capitalize).join
        end

        private

        def adapter_path
          parts = ["lib/reins/adapters", @direction.to_s, @namespace, file_basename].compact
          @scope == :lib ? "#{parts.join('/')}.rb" : "app/adapters/#{file_basename}.rb"
        end

        def spec_path
          parts = ["spec/reins/adapters", @direction.to_s, @namespace, file_basename].compact
          @scope == :lib ? "#{parts.join('/')}_spec.rb" : "spec/adapters/#{file_basename}_spec.rb"
        end

        def namespace_module
          return nil if @namespace.nil?

          @namespace.split("_").map(&:capitalize).join
        end

        def lib_open_namespace(indent)
          return "" if namespace_module.nil?

          "#{' ' * indent}module #{namespace_module}\n"
        end

        def lib_close_namespace(indent)
          return "" if namespace_module.nil?

          "#{' ' * indent}end\n"
        end

        def adapter_content
          if @direction == :driven
            driven_adapter_content
          else
            driving_adapter_content
          end
        end

        def driven_adapter_content
          method_stubs = stubs_for_contract
          if @scope == :app
            wrap_app_class(driven_body(method_stubs,
                                       2))
          else
            wrap_lib_class(driven_body(method_stubs, base_indent))
          end
        end

        def stubs_for_contract
          return "# TODO: implement methods from #{@port_module_name}::CONTRACT" if @port_module.nil?

          contract = @port_module.const_get(:CONTRACT)
          contract.map { |name, arity| method_stub(name, arity) }.join("\n\n")
        end

        def driving_adapter_content
          @scope == :app ? wrap_app_class(driving_body(2)) : wrap_lib_class(driving_body(base_indent))
        end

        def driven_body(method_stubs, leading_indent)
          inner = "include #{@port_module_name}\n\n#{indent(method_stubs, leading_indent)}".rstrip
          "#{inner}\n"
        end

        def driving_body(_leading_indent)
          <<~RUBY.chomp
            def initialize(app)
              @app = app
            end

            # def call(input)
            #   translated = translate_in(input)
            #   response = @app.call(translated)
            #   translate_out(response)
            # end
          RUBY
        end

        def wrap_app_class(body)
          <<~RUBY
            require "#{@port_require}"

            class #{class_name}
            #{indent(body, 2)}end
          RUBY
        end

        def wrap_lib_class(body)
          direction_module = @direction.to_s.capitalize
          inner_indent = namespace_module ? 10 : 8
          pad = " " * (inner_indent - 2)
          class_block = "#{pad}class #{class_name}\n#{indent(body, inner_indent)}#{pad}end\n"
          ns_open = lib_open_namespace(inner_indent - 4)
          ns_close = lib_close_namespace(inner_indent - 4)

          <<~RUBY
            require "#{@port_require}"

            module Reins
              module Adapters
                module #{direction_module}
            #{ns_open}#{class_block}#{ns_close}      end
              end
            end
          RUBY
        end

        def base_indent
          namespace_module ? 10 : 8
        end

        def spec_content
          if @direction == :driven
            driven_spec_content
          else
            driving_spec_content
          end
        end

        def driven_spec_content
          full_class = full_class_name
          <<~RUBY
            require "spec_helper"

            RSpec.describe #{full_class} do
              let(:adapter) { described_class.new }

              it "responds to every method on the #{@port_module_name} port contract" do
                #{@port_module_name}::CONTRACT.each_key do |name|
                  expect(adapter).to respond_to(name), "missing \#{name} on #{full_class}"
                end
              end
            end
          RUBY
        end

        def driving_spec_content
          full_class = full_class_name
          <<~RUBY
            require "spec_helper"

            RSpec.describe #{full_class} do
              let(:fake_app) { ->(_input) { } }
              let(:adapter) { described_class.new(fake_app) }

              it "is constructed with a port-implementing app" do
                expect(adapter).to be_a(described_class)
              end
            end
          RUBY
        end

        def method_stub(name, arity)
          params = stub_params(arity)
          <<~RUBY.chomp
            def #{name}(#{params})
              raise NotImplementedError, "#{class_name}##{name} not implemented"
            end
          RUBY
        end

        def full_class_name
          return class_name if @scope == :app

          parts = ["Reins", "Adapters", @direction.to_s.capitalize, namespace_module, class_name].compact
          parts.join("::")
        end

        def stub_params(arity)
          if arity == -1
            "*_args, **_kwargs"
          elsif arity.negative?
            required = -arity - 1
            required_args = Array.new(required) { |i| "_arg#{i}" }
            (required_args + ["*_rest"]).join(", ")
          else
            Array.new(arity) { |i| "_arg#{i}" }.join(", ")
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
