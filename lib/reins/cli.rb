require 'thor'
require 'fileutils'
require 'puma'
require 'rack'

module Reins
  class Cli < Thor
    desc "new", "Create a new Reins project"
    def new(name)
      scaffold_project(name)
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

    private

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

    def scaffold_project(dir)
      FileUtils.mkdir(dir)
      FileUtils.mkdir("#{dir}/app")
      FileUtils.mkdir("#{dir}/app/controllers")
      FileUtils.mkdir("#{dir}/app/views")
      FileUtils.mkdir("#{dir}/app/views/welcome")
      FileUtils.mkdir("#{dir}/config")
      FileUtils.mkdir("#{dir}/public")
      FileUtils.cp("#{File.dirname(__FILE__)}/../../assets/500.html", "#{dir}/public/500.html")
    end
  end
end
