require "tmpdir"
require "fileutils"

module ModelSpecSetup
  def setup_test_db
    @tmp_db_dir = Dir.mktmpdir
    Reins::Database.reset!
    Reins::Model::Base.reset_adapters!
    Reins::Database.path = File.join(@tmp_db_dir, "test.db")
  end

  def teardown_test_db
    Reins::Database.reset!
    Reins::Model::Base.reset_adapters!
    FileUtils.rm_rf(@tmp_db_dir) if @tmp_db_dir
  end

  def create_table(name, columns_sql)
    Reins::Database.connection.execute("CREATE TABLE #{name} (#{columns_sql})")
  end

  def db
    Reins::Database.connection
  end
end

RSpec.configure do |config|
  config.include ModelSpecSetup
end
