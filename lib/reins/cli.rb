require 'thor'
require 'fileutils'
require 'puma'
require 'rack'

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

    desc "generate TYPE NAME [field:type ...]", "Generate scaffolding (migration / controller / model / scaffold)"
    def generate(type, name, *fields)
      case type
      when "migration"
        generate_migration(name, fields)
      when "controller"
        Reins::Generators::ControllerGenerator.new(name, fields).run
      when "model"
        Reins::Generators::ModelGenerator.new(name, fields).run
      when "scaffold"
        Reins::Generators::ScaffoldGenerator.new(name, fields).run
      else
        warn "unknown generator: #{type}"
        exit 1
      end
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
