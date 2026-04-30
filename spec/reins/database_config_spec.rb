require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Reins::DatabaseConfig do
  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        FileUtils.mkdir_p("config")
        original_env = ENV.fetch("REINS_ENV", nil)
        example.run
      ensure
        ENV["REINS_ENV"] = original_env
        Reins::Database.reset!
      end
    end
  end

  def write_database_yml
    File.write("config/database.yml", <<~YAML)
      development:
        database: db/dev.sqlite3
      test:
        database: db/test.sqlite3
      production:
        database: db/prod.sqlite3
    YAML
  end

  it "load! reads config/database.yml and sets Database.path for the current env" do
    write_database_yml
    ENV["REINS_ENV"] = "development"
    described_class.load!
    expect(Reins::Database.path).to end_with("db/dev.sqlite3")
  end

  it "picks the section matching REINS_ENV (defaults to development)" do
    write_database_yml
    ENV["REINS_ENV"] = "test"
    described_class.load!
    expect(Reins::Database.path).to end_with("db/test.sqlite3")

    ENV["REINS_ENV"] = nil
    Reins::Database.reset!
    described_class.load!
    expect(Reins::Database.path).to end_with("db/dev.sqlite3")
  end

  it "raises a clear error when config/database.yml is missing" do
    expect { described_class.load! }.to raise_error(/database\.yml/i)
  end
end
