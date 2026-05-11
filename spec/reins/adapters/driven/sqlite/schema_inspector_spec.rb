require "spec_helper"

RSpec.describe Reins::Adapters::Driven::Sqlite::SchemaInspector do
  before do
    setup_test_db
    create_table "posts", "id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR, body TEXT"
    create_table "users", "id INTEGER PRIMARY KEY AUTOINCREMENT, email VARCHAR"
    @inspector = described_class.new(Reins::Database.connection)
  end

  after { teardown_test_db }

  it "includes the SchemaInspector port" do
    expect(described_class.include?(Reins::Ports::Driven::SchemaInspector)).to be(true)
  end

  it "responds to every method on the SchemaInspector port contract" do
    Reins::Ports::Driven::SchemaInspector::CONTRACT.each_key do |name|
      expect(@inspector).to respond_to(name), "missing #{name} on Sqlite::SchemaInspector"
    end
  end

  it "#columns returns name -> type for the table" do
    expect(@inspector.columns("posts")).to eq(
      "id" => "INTEGER",
      "title" => "VARCHAR",
      "body" => "TEXT"
    )
  end

  it "#tables returns user-defined tables" do
    expect(@inspector.tables).to contain_exactly("posts", "users")
  end
end
