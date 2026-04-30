require "yaml"
require "reins/database"

module Reins
  module DatabaseConfig
    DEFAULT_PATH = "config/database.yml".freeze

    def self.load!(path: DEFAULT_PATH, env: nil)
      env ||= ENV["REINS_ENV"] || "development"
      raise "config/database.yml not found at #{File.expand_path(path)}" unless File.exist?(path)

      config = YAML.safe_load_file(path, permitted_classes: [Symbol], aliases: true)
      section = config[env] || config[env.to_sym]
      raise "no '#{env}' section in #{path}" unless section

      Reins::Database.path = section["database"] || section[:database]
    end
  end
end
