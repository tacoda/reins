require "spec_helper"

RSpec.describe Reins::Adapters::Driven::Sqlite::SchemaMigrator do
  before do
    setup_test_db
    @migrator = described_class.new(Reins::Database.connection)
  end

  after { teardown_test_db }

  def column_info(table)
    Reins::Database.connection.execute("PRAGMA table_info(#{table})")
  end

  def column_named(table, name)
    column_info(table).find { |row| (row.is_a?(Hash) ? row["name"] : row[1]) == name.to_s }
  end

  it "includes the SchemaMigrator port" do
    expect(described_class.include?(Reins::Ports::Driven::SchemaMigrator)).to be(true)
  end

  it "responds to every method on the SchemaMigrator port contract" do
    Reins::Ports::Driven::SchemaMigrator::CONTRACT.each_key do |name|
      expect(@migrator).to respond_to(name), "missing #{name} on Sqlite::SchemaMigrator"
    end
  end

  describe "#create_table" do
    it "creates a table with an auto-increment id and named columns" do
      @migrator.create_table(:posts, [
                               { name: :title, type: :string },
                               { name: :body, type: :text }
                             ])
      expect(column_named(:posts, :id)).not_to be_nil
      expect(column_named(:posts, :title)).not_to be_nil
      expect(column_named(:posts, :body)).not_to be_nil
    end

    it "maps each shorthand type to the right SQL type" do
      @migrator.create_table(:things, [
                               { name: :s, type: :string },
                               { name: :tx, type: :text },
                               { name: :i, type: :integer },
                               { name: :f, type: :float },
                               { name: :b, type: :boolean },
                               { name: :dt, type: :datetime }
                             ])
      type = ->(name) { column_named(:things, name).then { |r| r.is_a?(Hash) ? r["type"] : r[2] } }
      aggregate_failures do
        expect(type.call(:s)).to  match(/VARCHAR|TEXT/i)
        expect(type.call(:tx)).to match(/TEXT/i)
        expect(type.call(:i)).to  match(/INTEGER/i)
        expect(type.call(:f)).to  match(/FLOAT|REAL/i)
        expect(type.call(:b)).to  match(/BOOLEAN/i)
        expect(type.call(:dt)).to match(/DATETIME|TEXT/i)
      end
    end
  end

  describe "#drop_table" do
    it "removes the table" do
      @migrator.create_table(:posts, [{ name: :title, type: :string }])
      @migrator.drop_table(:posts)
      tables = Reins::Database.connection.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='posts'"
      )
      expect(tables).to be_empty
    end
  end

  describe "#add_column / #remove_column" do
    it "adds and removes columns" do
      @migrator.create_table(:posts, [{ name: :title, type: :string }])
      @migrator.add_column(:posts, :status, :string)
      expect(column_named(:posts, :status)).not_to be_nil
      @migrator.remove_column(:posts, :status)
      expect(column_named(:posts, :status)).to be_nil
    end
  end

  describe "#add_index / #remove_index" do
    it "creates and drops an index, supporting unique:" do
      @migrator.create_table(:posts, [{ name: :slug, type: :string }])
      @migrator.add_index(:posts, :slug, unique: true)

      indexes = Reins::Database.connection.execute("PRAGMA index_list(posts)")
      expect(indexes.find { |r| (r.is_a?(Hash) ? r["unique"] : r[2]) == 1 }).not_to be_nil

      @migrator.remove_index(:posts, :slug)
      indexes_after = Reins::Database.connection.execute("PRAGMA index_list(posts)")
      expect(indexes_after.size).to be < indexes.size
    end
  end

  describe "#rename_column" do
    it "renames the column" do
      @migrator.create_table(:posts, [{ name: :title, type: :string }])
      @migrator.rename_column(:posts, :title, :headline)
      expect(column_named(:posts, :title)).to be_nil
      expect(column_named(:posts, :headline)).not_to be_nil
    end
  end

  describe "#execute" do
    it "runs raw SQL as the escape hatch" do
      @migrator.execute("CREATE TABLE raw (id INTEGER)")
      expect(column_named(:raw, :id)).not_to be_nil
    end
  end
end
