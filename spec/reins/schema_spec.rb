require "spec_helper"

RSpec.describe Reins::Schema do
  around do |example|
    setup_test_db
    example.run
  ensure
    teardown_test_db
  end

  it "Reins::Schema.define recreates tables (same DSL as migrations)" do
    described_class.define(version: "20260101000000") do
      create_table :posts do |t|
        t.string :title
        t.text   :body
      end
    end

    rows = Reins::Database.connection.execute(
      "SELECT name FROM sqlite_master WHERE type='table' AND name = 'posts'"
    )
    expect(rows).not_to be_empty
  end

  it "Reins::Schema.dump_string produces a re-runnable schema.rb body" do
    Reins::Database.connection.execute(<<~SQL)
      CREATE TABLE posts (id INTEGER PRIMARY KEY, title TEXT, body TEXT)
    SQL

    dump = described_class.dump_string

    expect(dump).to include("Reins::Schema.define")
    expect(dump).to include('create_table "posts"')
    expect(dump).to include('"title"')
    expect(dump).to include('"body"')
  end
end
