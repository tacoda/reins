require "spec_helper"

RSpec.describe Reins::Migrator do
  around do |example|
    setup_test_db
    @migrations_dir = Dir.mktmpdir
    example.run
  ensure
    FileUtils.rm_rf(@migrations_dir) if @migrations_dir
    teardown_test_db
  end

  def write_migration(version:, name:, body:)
    class_name = name.split("_").map(&:capitalize).join
    File.write(
      File.join(@migrations_dir, "#{version}_#{name}.rb"),
      <<~RUBY
        class #{class_name} < Reins::Migration
          #{body}
        end
      RUBY
    )
  end

  def migrator
    described_class.new(migrations_path: @migrations_dir)
  end

  def table_exists?(name)
    rows = Reins::Database.connection.execute(
      "SELECT name FROM sqlite_master WHERE type='table' AND name = ?", [name.to_s]
    )
    rows.any?
  end

  def applied_versions
    Reins::Database.connection.execute("SELECT version FROM schema_migrations ORDER BY version")
                   .map { |r| r.is_a?(Hash) ? r["version"] : r[0] }
  end

  it "applies all pending migrations in timestamp order" do
    write_migration(version: "20260102000000", name: "create_widgets",
                    body: "def change; create_table(:widgets) { |t| t.string :name }; end")
    write_migration(version: "20260101000000", name: "create_posts",
                    body: "def change; create_table(:posts) { |t| t.string :title }; end")

    migrator.run

    expect(table_exists?(:posts)).to be(true)
    expect(table_exists?(:widgets)).to be(true)
    expect(applied_versions).to eq(%w[20260101000000 20260102000000])
  end

  it "skips migrations whose version is in schema_migrations" do
    write_migration(version: "20260101000000", name: "create_posts",
                    body: "def change; create_table(:posts) { |t| t.string :title }; end")
    migrator.run
    expect { migrator.run }.not_to raise_error
    expect(applied_versions).to eq(%w[20260101000000])
  end

  it "rollback(n) runs `down` (or inverted change) for the last n applied" do
    write_migration(version: "20260101000000", name: "create_posts",
                    body: "def change; create_table(:posts) { |t| t.string :title }; end")
    write_migration(version: "20260102000000", name: "create_widgets",
                    body: "def change; create_table(:widgets) { |t| t.string :name }; end")
    migrator.run

    migrator.rollback(1)
    expect(table_exists?(:widgets)).to be(false)
    expect(table_exists?(:posts)).to be(true)
    expect(applied_versions).to eq(%w[20260101000000])
  end

  it "a change-only migration is reversible when it uses only supported ops" do
    write_migration(
      version: "20260101000000", name: "create_posts",
      body: <<~RUBY
        def change
          create_table(:posts) { |t| t.string :title }
          add_column :posts, :status, :string
          add_index :posts, :status
        end
      RUBY
    )
    migrator.run
    migrator.rollback(1)
    expect(table_exists?(:posts)).to be(false)
    expect(applied_versions).to be_empty
  end

  it "change-only with non-reversible op raises Reins::IrreversibleMigration on rollback" do
    write_migration(
      version: "20260101000000", name: "do_stuff",
      body: <<~RUBY
        def change
          create_table(:posts) { |t| t.string :title }
          rename_column :posts, :title, :headline
        end
      RUBY
    )
    migrator.run
    expect { migrator.rollback(1) }.to raise_error(Reins::IrreversibleMigration)
  end

  it "creates schema_migrations on first run" do
    expect(table_exists?(:schema_migrations)).to be(false)
    write_migration(version: "20260101000000", name: "create_posts",
                    body: "def change; create_table(:posts) { |t| t.string :title }; end")
    migrator.run
    expect(table_exists?(:schema_migrations)).to be(true)
  end
end
