require "reins/generators/controller_generator"
require "reins/generators/model_generator"
require "reins/generators/scaffold_generator"
require "reins/core/generators/port_generator"
require "reins/core/generators/adapter_generator"
require "reins/core/generators/port_presets"
require "reins/core/generators/blueprint_writer"
require "reins/util"

module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins generate TYPE …`. Dispatches to the right
        # generator based on type and writes the resulting Blueprint through
        # the FileSystem port. The Thor adapter parses flags and passes them
        # as a Hash; this command makes no Thor calls.
        class Generate
          PRESETS = Reins::Core::Generators::PortPresets.names.freeze

          def initialize(file_system:, clock: nil)
            @file_system = file_system
            @clock = clock
          end

          def run(type, name = nil, fields: [], options: {})
            case type
            when "migration"  then generate_migration(name, fields)
            when "controller" then run_blueprint(Reins::Generators::ControllerGenerator.new(name, fields).blueprint)
            when "model"      then run_blueprint(Reins::Generators::ModelGenerator.new(name, fields).blueprint)
            when "scaffold"   then run_scaffold(name, fields)
            when "port"       then generate_port(name, options)
            when "adapter"    then generate_adapter(name, options)
            else
              raise "unknown generator: #{type}"
            end
          end

          private

          def run_blueprint(blueprint)
            writer.write(blueprint)
          end

          def run_scaffold(name, fields)
            blueprint = Reins::Generators::ScaffoldGenerator.new(name, fields, file_system: @file_system).blueprint
            writer.write(blueprint)
          end

          def generate_port(name, options)
            return print_preset_list if options[:list]

            preset = PRESETS.find { |p| options[p] }
            scope = detect_scope

            if preset
              writer.write(Reins::Core::Generators::PortPresets.fetch(preset.to_sym, scope: scope))
            else
              raise "generate port requires a NAME (or a preset flag like --rack)" if name.nil? || name.empty?

              direction = options[:driving] ? :driving : :driven
              writer.write(Reins::Core::Generators::PortGenerator.new(name, direction: direction,
                                                                            scope: scope).blueprint)
            end
          end

          def generate_adapter(name, options)
            port_name = options[:port]
            raise "generate adapter requires --port=PORT_NAME" if port_name.nil? || port_name.empty?
            raise "generate adapter requires a NAME" if name.nil? || name.empty?

            scope = detect_scope
            direction = options[:driving] ? :driving : :driven
            port_module, port_module_name, port_require = resolve_port(port_name, scope)

            writer.write(
              Reins::Core::Generators::AdapterGenerator.new(
                name,
                port_module: port_module,
                port_module_name: port_module_name,
                port_require: port_require,
                direction: direction,
                scope: scope
              ).blueprint
            )
          end

          def generate_migration(name, fields)
            timestamp = (@clock || Time).now.utc.strftime("%Y%m%d%H%M%S")
            snake = Reins.to_underscore(name)
            file_path = "db/migrate/#{timestamp}_#{snake}.rb"
            @file_system.mkdir_p("db/migrate")
            @file_system.write(file_path, migration_template(name, fields))
          end

          def migration_template(name, fields)
            body = migration_body(name, fields)
            <<~RUBY
              class #{name} < Reins::Migration
                def change
              #{body}  end
              end
            RUBY
          end

          def migration_body(name, fields)
            return "" if fields.empty?

            match = name.match(/\AAdd.+?To(.+)\z/) || name.match(/\ARemove.+?From(.+)\z/)
            return "" unless match

            table = Reins.to_underscore(match[1])
            fields.map do |field|
              attr_name, attr_type = field.split(":", 2)
              "    add_column :#{table}, :#{attr_name}, :#{attr_type}\n"
            end.join
          end

          def print_preset_list
            Reins::Core::Generators::PortPresets.descriptions.each do |name, description|
              puts "  --#{name.to_s.ljust(12)}  #{description}"
            end
          end

          def detect_scope
            @file_system.exist?("lib/reins.rb") ? :lib : :app
          end

          def resolve_port(port_name, scope)
            if scope == :app
              require_path = Reins.to_underscore(port_name)
              camel = require_path.split("_").map(&:capitalize).join
              port_file = "app/ports/#{require_path}.rb"
              load(port_file) if @file_system.exist?(port_file)
              port_module = Object.const_defined?(camel) ? Object.const_get(camel) : nil
              [port_module, camel, require_path]
            else
              [nil, port_name, Reins.to_underscore(port_name).delete_prefix("/")]
            end
          end

          def writer
            @writer ||= Reins::Core::Generators::BlueprintWriter.new(@file_system)
          end
        end
      end
    end
  end
end
