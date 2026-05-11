require 'thor'
require 'fileutils'
require 'puma'
require 'rack'
require 'reins/core/generators/blueprint_writer'
require 'reins/core/generators/port_generator'
require 'reins/core/generators/adapter_generator'
require 'reins/core/generators/port_presets'
require 'reins/adapters/driven/filesystem/real'

module Reins
  class Cli < Thor
    desc "new NAME", "Create a new Reins project at NAME"
    def new(name)
      Reins::Generators::AppGenerator.new(name).run
      puts "Created #{name}/"
      puts "Now run: cd #{name} && bin/setup"
    end

    desc "server", "Run a local server"
    def server
      root = File.expand_path(Dir.pwd.to_s)
      config = "#{root}/config.ru"

      app = Rack::Builder.load_file(config)

      server = Puma::Server.new(app)
      server.add_tcp_listener('0.0.0.0', 8000)

      trap('INT') do
        server.stop
        puts "\nServer stopped."
        exit
      end

      puts "Serving files from #{root} on http://localhost:8000"
      server.run.join
    end

    desc "routes", "List all defined routes"
    def routes
      config = File.join(Dir.pwd, "config.ru")
      unless File.exist?(config)
        warn "config.ru not found in #{Dir.pwd}"
        exit 1
      end

      Rack::Builder.parse_file(config)
      app = Reins::Application.instances.last

      if app.nil? || app.routes.nil?
        warn "No Reins::Application with routes was loaded from config.ru"
        exit 1
      end

      print_routes_table(app.routes.rules)
    end

    PRESET_FLAGS = Reins::Core::Generators::PortPresets.names.freeze
    PRESET_FLAGS.each do |preset|
      method_option preset, type: :boolean, default: false
    end
    method_option :driving, type: :boolean, default: false
    method_option :driven, type: :boolean, default: false
    method_option :port, type: :string
    method_option :list, type: :boolean, default: false

    desc "generate TYPE [NAME] [field:type ...]",
         "Generate scaffolding (migration / controller / model / scaffold / port / adapter)"
    def generate(type, name = nil, *fields)
      case type
      when "migration"  then generate_migration(name, fields)
      when "controller" then Reins::Generators::ControllerGenerator.new(name, fields).run
      when "model"      then Reins::Generators::ModelGenerator.new(name, fields).run
      when "scaffold"   then Reins::Generators::ScaffoldGenerator.new(name, fields).run
      when "port"       then generate_port(name)
      when "adapter"    then generate_adapter(name)
      else
        warn "unknown generator: #{type}"
        exit 1
      end
    end

    desc "test [ARGS...]", "Run the test suite (shells out to `bundle exec rspec`)"
    def test(*)
      system("bundle", "exec", "rspec", *)
    end

    desc "console", "Open IRB with the application loaded"
    def console
      unless File.exist?("config/application.rb")
        warn "config/application.rb not found in #{Dir.pwd}"
        exit 1
      end

      load "config/application.rb"
      Reins::Application.subclasses.last&.new
      load "config/routes.rb" if File.exist?("config/routes.rb")

      require "irb"
      IRB.start
    end

    map "db:create" => :db_create
    desc "db:create", "Create the configured database"
    def db_create
      Reins::DatabaseConfig.load!
      FileUtils.mkdir_p(File.dirname(Reins::Database.path))
      Reins::Database.connection.execute("SELECT 1")
      puts "Created #{Reins::Database.path}"
    end

    map "db:drop" => :db_drop
    desc "db:drop", "Drop the configured database"
    def db_drop
      Reins::DatabaseConfig.load!
      path = Reins::Database.path
      Reins::Database.reset!
      FileUtils.rm_f(path)
      puts "Dropped #{path}"
    end

    map "db:migrate" => :db_migrate
    desc "db:migrate", "Run pending migrations"
    def db_migrate
      Reins::DatabaseConfig.load!
      Reins::Migrator.new.run
    end

    map "db:rollback" => :db_rollback
    desc "db:rollback [STEPS]", "Roll back the last STEPS migrations (default 1)"
    def db_rollback(steps = "1")
      Reins::DatabaseConfig.load!
      Reins::Migrator.new.rollback(Integer(steps))
    end

    map "db:schema:dump" => :db_schema_dump
    desc "db:schema:dump", "Write db/schema.rb from current database state"
    def db_schema_dump
      Reins::DatabaseConfig.load!
      Reins::Schema.dump
      puts "Wrote db/schema.rb"
    end

    private

    def generate_port(name)
      return print_preset_list if options[:list]

      preset = PRESET_FLAGS.find { |p| options[p] }
      scope = detect_scope

      if preset
        write_blueprint(Reins::Core::Generators::PortPresets.fetch(preset.to_sym, scope: scope))
      else
        if name.nil? || name.empty?
          warn "generate port requires a NAME (or a preset flag like --rack)"
          exit 1
        end
        direction = options[:driving] ? :driving : :driven
        write_blueprint(
          Reins::Core::Generators::PortGenerator.new(name, direction: direction, scope: scope).blueprint
        )
      end
    end

    def generate_adapter(name)
      port_name = options[:port]
      if port_name.nil? || port_name.empty?
        warn "generate adapter requires --port=PORT_NAME"
        exit 1
      end
      if name.nil? || name.empty?
        warn "generate adapter requires a NAME"
        exit 1
      end

      scope = detect_scope
      direction = options[:driving] ? :driving : :driven
      port_module, port_module_name, port_require = resolve_port(port_name, scope, direction)

      write_blueprint(
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

    def print_preset_list
      Reins::Core::Generators::PortPresets.descriptions.each do |name, description|
        puts "  --#{name.to_s.ljust(12)}  #{description}"
      end
    end

    def detect_scope
      File.exist?(File.join(Dir.pwd, "lib", "reins.rb")) ? :lib : :app
    end

    def resolve_port(port_name, scope, _direction)
      if scope == :app
        require_path = Reins.to_underscore(port_name)
        camel = require_path.split("_").map(&:capitalize).join
        port_file = "app/ports/#{require_path}.rb"
        load(port_file) if File.exist?(port_file)
        port_module = Object.const_defined?(camel) ? Object.const_get(camel) : nil
        [port_module, camel, require_path]
      else
        [nil, port_name, Reins.to_underscore(port_name).delete_prefix("/")]
      end
    end

    def write_blueprint(blueprint)
      fs = Reins::Adapters::Driven::Filesystem::Real.new
      Reins::Core::Generators::BlueprintWriter.new(fs).write(blueprint)
    end

    def generate_migration(name, fields)
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      snake = Reins.to_underscore(name)
      file_path = "db/migrate/#{timestamp}_#{snake}.rb"
      FileUtils.mkdir_p("db/migrate")
      File.write(file_path, migration_template(name, fields))
      puts "Created #{file_path}"
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

      table = inferred_table(name)
      return "" unless table

      fields.map do |field|
        attr_name, attr_type = field.split(":", 2)
        "    add_column :#{table}, :#{attr_name}, :#{attr_type}\n"
      end.join
    end

    def inferred_table(name)
      match = name.match(/\AAdd.+?To(.+)\z/) || name.match(/\ARemove.+?From(.+)\z/)
      Reins.to_underscore(match[1]) if match
    end

    def print_routes_table(rules)
      rows = build_rows(rules)
      widths = column_widths(rows)
      puts format_row(%w[Prefix Verb] + ["URI Pattern", "Controller#Action"], widths)
      rows.each { |row| puts format_row(row, widths) }
    end

    def build_rows(rules)
      rules.flat_map do |rule|
        rule.verbs_for_allow_header.map do |verb|
          [rule.name.to_s, verb, rule.pattern, rule.dest.to_s]
        end
      end
    end

    def column_widths(rows)
      headers = ["Prefix", "Verb", "URI Pattern", "Controller#Action"]
      (0..3).map do |i|
        ([headers[i]] + rows.map { |r| r[i] }).map(&:length).max
      end
    end

    def format_row(row, widths)
      row.each_with_index.map { |cell, i| cell.ljust(widths[i]) }.join("  ")
    end
  end
end
