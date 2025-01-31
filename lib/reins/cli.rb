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
      root = File.expand_path("#{Dir.pwd}")
      config = root + "/config.ru"

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

    private

    def scaffold_project(dir)
      FileUtils.mkdir(dir)
      FileUtils.mkdir(dir + "/app")
      FileUtils.mkdir(dir + "/app/controllers")
      FileUtils.mkdir(dir + "/app/views")
      FileUtils.mkdir(dir + "/app/views/welcome")
      FileUtils.mkdir(dir + "/config")
      FileUtils.mkdir(dir + "/public")
      FileUtils.cp(File.dirname(__FILE__) + "/../../assets/500.html", "testdir/public/500.html")
    end
  end
end
