require "reins/migration"

module Reins
  module Schema
    SKIP_TABLES = %w[sqlite_sequence schema_migrations].freeze

    def self.define(version: nil, &block)
      klass = Class.new(Reins::Migration)
      klass.define_method(:change, &block) if block
      klass.new.run_up
      record_version(version) if version
    end

    def self.dump(path: "db/schema.rb")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, dump_string)
    end

    def self.dump_string
      tables = list_tables.reject { |t| SKIP_TABLES.include?(t) }
      version = current_version
      lines = []
      lines << "Reins::Schema.define(#{"version: #{version.to_s.inspect}" if version}) do"
      tables.each do |table|
        lines.concat(table_definition_lines(table))
        lines << ""
      end
      lines << "end"
      "#{lines.join("\n")}\n"
    end

    def self.list_tables
      Reins::Database.connection
                     .execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
                     .map { |row| row.is_a?(Hash) ? row["name"] : row[0] }
    end

    def self.list_columns(table)
      Reins::Database.connection.execute("PRAGMA table_info(#{table})")
    end

    def self.record_version(version)
      Reins::Database.connection.execute(
        "CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR PRIMARY KEY)"
      )
      Reins::Database.connection.execute(
        "INSERT OR IGNORE INTO schema_migrations (version) VALUES (?)", [version.to_s]
      )
    end

    def self.current_version
      row = Reins::Database.connection.execute(
        "SELECT MAX(version) AS v FROM schema_migrations"
      ).first
      return nil if row.nil?

      row.is_a?(Hash) ? row["v"] : row[0]
    rescue StandardError
      nil
    end

    def self.table_definition_lines(table)
      cols = list_columns(table)
      lines = ["  create_table \"#{table}\" do |t|"]
      cols.each do |row|
        name = row.is_a?(Hash) ? row["name"] : row[1]
        type = row.is_a?(Hash) ? row["type"] : row[2]
        next if name == "id"

        lines << "    t.#{sql_type_to_dsl(type)} \"#{name}\""
      end
      lines << "  end"
      lines
    end

    def self.sql_type_to_dsl(type)
      case type.to_s.upcase
      when /TEXT/ then :text
      when /INT/ then :integer
      when /FLOAT/, /REAL/, /NUMERIC/ then :float
      when /BOOL/ then :boolean
      when /DATETIME/ then :datetime
      else :string # VARCHAR, CHAR, and any unknown type
      end
    end
  end
end
