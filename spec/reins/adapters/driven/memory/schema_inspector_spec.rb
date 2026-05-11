require "spec_helper"

RSpec.describe Reins::Adapters::Driven::Memory::SchemaInspector do
  let(:inspector) do
    described_class.new(
      "posts" => { "id" => "INTEGER", "title" => "VARCHAR" },
      "users" => { "id" => "INTEGER", "email" => "VARCHAR" }
    )
  end

  it "includes the SchemaInspector port" do
    expect(described_class.include?(Reins::Ports::Driven::SchemaInspector)).to be(true)
  end

  it "responds to every method on the SchemaInspector port contract" do
    Reins::Ports::Driven::SchemaInspector::CONTRACT.each_key do |name|
      expect(inspector).to respond_to(name), "missing #{name} on Memory::SchemaInspector"
    end
  end

  it "#columns returns the configured Hash for the table" do
    expect(inspector.columns("posts")).to eq("id" => "INTEGER", "title" => "VARCHAR")
  end

  it "#tables returns the configured list" do
    expect(inspector.tables).to contain_exactly("posts", "users")
  end

  it "#columns returns an empty Hash for an unknown table" do
    expect(inspector.columns("nope")).to eq({})
  end
end
