require "reins/migration"

module Reins
  class Migrator
    DEFAULT_PATH = "db/migrate".freeze

    def initialize(migrations_path: DEFAULT_PATH)
      @migrations_path = migrations_path
    end

    def run
      ensure_schema_migrations_table
      pending_files.each do |file|
        version, klass = load_migration(file)
        Reins::Database.connection.transaction do
          klass.new.run_up
          record_version(version)
        end
        say "migrated  #{version}"
      end
    end

    def rollback(steps = 1)
      ensure_schema_migrations_table
      versions_to_undo = applied_versions.last(steps).reverse
      versions_to_undo.each do |version|
        file = find_file_for(version)
        _v, klass = load_migration(file)
        Reins::Database.connection.transaction do
          klass.new.run_down
          remove_version(version)
        end
        say "rolled back  #{version}"
      end
    end

    def applied_versions
      ensure_schema_migrations_table
      rows = Reins::Database.connection.execute(
        "SELECT version FROM schema_migrations ORDER BY version"
      )
      rows.map { |row| row.is_a?(Hash) ? row["version"] : row[0] }
    end

    private

    def all_files
      Dir.glob("#{@migrations_path}/*.rb")
    end

    def pending_files
      done = applied_versions
      all_files.reject { |f| done.include?(extract_version(f)) }
    end

    def find_file_for(version)
      all_files.find { |f| extract_version(f) == version }
    end

    def extract_version(path)
      File.basename(path).match(/\A(\d+)_/)[1]
    end

    def constantize(path)
      basename = File.basename(path, ".rb").split("_", 2)[1]
      basename.split("_").map(&:capitalize).join
    end

    def load_migration(file)
      version = extract_version(file)
      load(file)
      klass = Object.const_get(constantize(file))
      [version, klass]
    end

    def ensure_schema_migrations_table
      Reins::Database.connection.execute(
        "CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR PRIMARY KEY)"
      )
    end

    def record_version(version)
      Reins::Database.connection.execute(
        "INSERT INTO schema_migrations (version) VALUES (?)", [version]
      )
    end

    def remove_version(version)
      Reins::Database.connection.execute(
        "DELETE FROM schema_migrations WHERE version = ?", [version]
      )
    end

    def say(message)
      puts "  #{message}" if $stdout.tty? || ENV["REINS_VERBOSE"]
    end
  end
end
