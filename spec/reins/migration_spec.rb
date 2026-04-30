require "spec_helper"

RSpec.describe Reins::Migration do
  around do |example|
    setup_test_db
    example.run
  ensure
    teardown_test_db
  end

  def run_migration(&block)
    Class.new(described_class) { define_method(:change, &block) }.new.run_up
  end

  def column_info(table)
    Reins::Database.connection.execute("PRAGMA table_info(#{table})")
  end

  def column_named(table, name)
    column_info(table).find { |row| (row.is_a?(Hash) ? row["name"] : row[1]) == name.to_s }
  end

  def column_type(row)
    row.is_a?(Hash) ? row["type"] : row[2]
  end

  it "create_table issues CREATE TABLE with the right column type" do
    run_migration do
      create_table :posts do |t|
        t.string :title
      end
    end
    expect(column_type(column_named(:posts, :title))).to match(/VARCHAR|TEXT/i)
  end

  it "each column shorthand emits the expected SQL type" do
    run_migration do
      create_table :things do |t|
        t.string   :s
        t.text     :tx
        t.integer  :i
        t.float    :f
        t.boolean  :b
        t.datetime :dt
      end
    end
    aggregate_failures do
      expect(column_type(column_named(:things, :s))).to  match(/VARCHAR|TEXT/i)
      expect(column_type(column_named(:things, :tx))).to match(/TEXT/i)
      expect(column_type(column_named(:things, :i))).to  match(/INTEGER/i)
      expect(column_type(column_named(:things, :f))).to  match(/FLOAT|REAL/i)
      expect(column_type(column_named(:things, :b))).to  match(/BOOLEAN/i)
      expect(column_type(column_named(:things, :dt))).to match(/DATETIME|TEXT/i)
    end
  end

  it "t.timestamps adds created_at and updated_at columns" do
    run_migration do
      create_table :posts do |t|
        t.string :title
        t.timestamps
      end
    end
    expect(column_named(:posts, :created_at)).not_to be_nil
    expect(column_named(:posts, :updated_at)).not_to be_nil
  end

  it "t.references :author adds author_id INTEGER and an index" do
    run_migration do
      create_table :posts do |t|
        t.references :author
      end
    end
    expect(column_named(:posts, :author_id)).not_to be_nil
    indexes = Reins::Database.connection.execute("PRAGMA index_list(posts)")
    expect(indexes).not_to be_empty
  end

  it "add_column and remove_column produce the right ALTER TABLE statements" do
    run_migration do
      create_table(:posts) { |t| t.string :title }
    end
    Class.new(described_class) do
      def change
        add_column :posts, :status, :string
      end
    end.new.run_up

    expect(column_named(:posts, :status)).not_to be_nil

    Class.new(described_class) do
      def change
        remove_column :posts, :status
      end
    end.new.run_up

    expect(column_named(:posts, :status)).to be_nil
  end

  it "add_index :unique creates a unique index; remove_index drops it" do
    run_migration do
      create_table(:posts) { |t| t.string :slug }
      add_index :posts, :slug, unique: true
    end

    indexes = Reins::Database.connection.execute("PRAGMA index_list(posts)")
    unique_index = indexes.find { |row| (row.is_a?(Hash) ? row["unique"] : row[2]) == 1 }
    expect(unique_index).not_to be_nil

    Class.new(described_class) do
      def change
        remove_index :posts, :slug
      end
    end.new.run_up

    indexes_after = Reins::Database.connection.execute("PRAGMA index_list(posts)")
    expect(indexes_after.size).to be < indexes.size
  end

  it "rename_column renames the column" do
    run_migration do
      create_table(:posts) { |t| t.string :title }
      rename_column :posts, :title, :headline
    end
    expect(column_named(:posts, :title)).to be_nil
    expect(column_named(:posts, :headline)).not_to be_nil
  end

  it "change_column raises Reins::Migration::NotSupported" do
    klass = Class.new(described_class) do
      def change
        change_column :posts, :title, :text
      end
    end
    expect { klass.new.run_up }.to raise_error(Reins::Migration::NotSupported)
  end
end
