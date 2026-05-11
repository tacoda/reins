require "reins/core/generators/blueprint"
require "reins/util"

module Reins
  module Core
    module Generators
      # Scaffolds a use case — an application service object that takes its
      # dependencies via keyword args and exposes a #call entry point.
      # Reins doesn't require app authors to use this pattern; it's
      # available when the controller is doing more than one thing and
      # the action wants a name.
      class UseCaseGenerator
        DEFAULT_DEPS = %i[repository clock].freeze

        def initialize(name, deps = nil)
          @raw_name = name
          @deps = (deps && !deps.empty? ? deps : DEFAULT_DEPS).map(&:to_sym)
        end

        def blueprint
          bp = Blueprint.new
          bp.add_file(use_case_path, use_case_content)
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

        def use_case_path
          "app/use_cases/#{file_basename}.rb"
        end

        def spec_path
          "spec/use_cases/#{file_basename}_spec.rb"
        end

        def use_case_content
          params = @deps.map { |dep| "#{dep}: Reins.application.adapter(:#{dep})" }.join(",\n        ")
          assigns = @deps.map { |dep| "  @#{dep} = #{dep}" }.join("\n")

          <<~RUBY
            class #{class_name}
              def initialize(
                #{params}
              )
              #{assigns}
              end

              def call(*_args, **_kwargs)
                # TODO: implement #{class_name}. Available collaborators:
              #{@deps.map { |d| "  #   @#{d}" }.join("\n")}
              end
            end
          RUBY
        end

        def spec_content
          let_lines = @deps.map { |dep| "  let(:#{dep}) { #{double_for(dep)} }" }.join("\n")
          adapters_hash = @deps.map { |dep| "#{dep}: #{dep}" }.join(", ")

          <<~RUBY
            require "spec_helper"

            RSpec.describe #{class_name} do
            #{let_lines}

              let(:app) do
                Reins::Application.new(
                  profile: :test,
                  adapters: { #{adapters_hash} },
                  validate: false
                )
              end

              let(:use_case) { described_class.new(#{@deps.map { |d| "#{d}: app.adapter(:#{d})" }.join(', ')}) }

              it "executes the use case" do
                # use_case.call(...)
                # expect(#{@deps.first}.calls.last[:method]).to eq(:some_method)
              end
            end
          RUBY
        end

        def double_for(dep)
          case dep
          when :repository       then "Reins::Adapters::Driven::Memory::Repository.new"
          when :clock            then "Reins::Adapters::Driven::Memory::Clock.new(Time.utc(2026, 1, 1))"
          when :file_system      then "Reins::Adapters::Driven::Memory::FileSystem.new"
          when :env_reader       then "Reins::Adapters::Driven::Memory::EnvReader.new"
          when :process_runner   then "Reins::Adapters::Driven::Memory::ProcessRunner.new"
          when :template_store   then "Reins::Adapters::Driven::Memory::TemplateStore.new"
          else                        "double(#{dep.inspect})  # provide a real double for this collaborator"
          end
        end
      end
    end
  end
end
