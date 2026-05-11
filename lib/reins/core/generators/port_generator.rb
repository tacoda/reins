require "reins/core/generators/blueprint"
require "reins/util"

module Reins
  module Core
    module Generators
      # Generates a new port — a Ruby module that extends Reins::Port and
      # declares its direction and contract. The blueprint includes the port
      # file and a spec stub asserting the port's shape.
      #
      # Two scopes:
      # - :app  → app/ports/<name>.rb         module <CamelCase>
      # - :lib  → lib/reins/ports/<dir>/<...>  module Reins::Ports::Driving|Driven::<...>
      class PortGenerator
        VALID_DIRECTIONS = %i[driving driven].freeze
        VALID_SCOPES = %i[app lib].freeze

        def initialize(name, direction: :driven, scope: :app)
          raise ArgumentError, "unknown direction: #{direction.inspect}" unless VALID_DIRECTIONS.include?(direction)
          raise ArgumentError, "unknown scope: #{scope.inspect}" unless VALID_SCOPES.include?(scope)

          @raw_name = name
          @direction = direction
          @scope = scope
        end

        def blueprint
          bp = Blueprint.new
          bp.add_file(port_path, port_content)
          bp.add_file(spec_path, spec_content)
          bp
        end

        def file_basename
          @file_basename ||= Reins.to_underscore(@raw_name.to_s.tr("-", "_"))
        end

        def module_name
          @module_name ||= file_basename.split("_").map(&:capitalize).join
        end

        private

        def port_path
          case @scope
          when :app then "app/ports/#{file_basename}.rb"
          when :lib then "lib/reins/ports/#{@direction}/#{file_basename}.rb"
          end
        end

        def spec_path
          case @scope
          when :app then "spec/ports/#{file_basename}_spec.rb"
          when :lib then "spec/reins/ports/#{@direction}/#{file_basename}_spec.rb"
          end
        end

        def port_content
          @scope == :lib ? lib_port_content : app_port_content
        end

        def app_port_content
          <<~RUBY
            require "reins/port"

            module #{module_name}
              extend Reins::Port

              direction :#{@direction}

              contract({}) # TODO: declare port methods, e.g. find_all: 1, insert: 2
            end
          RUBY
        end

        def lib_port_content
          direction_module = @direction.to_s.capitalize
          <<~RUBY
            require "reins/port"

            module Reins
              module Ports
                module #{direction_module}
                  module #{module_name}
                    extend Reins::Port

                    direction :#{@direction}

                    contract({}) # TODO: declare port methods, e.g. find_all: 1, insert: 2
                  end
                end
              end
            end
          RUBY
        end

        def spec_content
          @scope == :lib ? lib_spec_content : app_spec_content
        end

        def app_spec_content
          <<~RUBY
            require "spec_helper"

            RSpec.describe #{module_name} do
              it "declares its direction" do
                expect(#{module_name}::DIRECTION).to eq(:#{@direction})
              end

              it "declares a frozen CONTRACT" do
                expect(#{module_name}::CONTRACT).to be_a(Hash)
                expect(#{module_name}::CONTRACT).to be_frozen
              end
            end
          RUBY
        end

        def lib_spec_content
          direction_module = @direction.to_s.capitalize
          full = "Reins::Ports::#{direction_module}::#{module_name}"
          <<~RUBY
            require "spec_helper"

            RSpec.describe #{full} do
              it "declares its direction" do
                expect(#{full}::DIRECTION).to eq(:#{@direction})
              end

              it "declares a frozen CONTRACT" do
                expect(#{full}::CONTRACT).to be_a(Hash)
                expect(#{full}::CONTRACT).to be_frozen
              end
            end
          RUBY
        end
      end
    end
  end
end
