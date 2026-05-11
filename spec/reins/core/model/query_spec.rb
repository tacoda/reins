require "spec_helper"

RSpec.describe Reins::Core::Model::Query do
  it "starts empty" do
    q = described_class.new(table: "posts")
    expect(q.table).to eq("posts")
    expect(q.wheres).to eq([])
    expect(q.orders).to eq([])
    expect(q.limit).to be_nil
    expect(q.offset).to be_nil
  end

  it "#add_where_fragment appends a fragment + params pair" do
    q = described_class.new(table: "posts")
    q.add_where_fragment("name = ?", ["foo"])
    expect(q.wheres).to eq([["name = ?", ["foo"]]])
  end

  it "#add_where_hash translates each entry to a fragment + params pair" do
    q = described_class.new(table: "posts")
    q.add_where_hash(name: "foo", age: 7)
    expect(q.wheres).to eq([
                             ["name = ?", ["foo"]],
                             ["age = ?", [7]]
                           ])
  end

  it "#add_order appends to orders" do
    q = described_class.new(table: "posts")
    q.add_order("name ASC")
    q.add_order("id DESC")
    expect(q.orders).to eq(["name ASC", "id DESC"])
  end

  it "#limit and #offset are writable" do
    q = described_class.new(table: "posts")
    q.limit = 10
    q.offset = 20
    expect(q.limit).to eq(10)
    expect(q.offset).to eq(20)
  end

  it "deep-copies wheres and orders on #dup" do
    a = described_class.new(table: "posts")
    a.add_where_hash(name: "foo")
    a.add_order("id ASC")
    b = a.dup
    b.add_where_hash(name: "bar")
    b.add_order("id DESC")

    expect(a.wheres.size).to eq(1)
    expect(a.orders.size).to eq(1)
    expect(b.wheres.size).to eq(2)
    expect(b.orders.size).to eq(2)
  end

  it "compares equal when fields match" do
    a = described_class.new(table: "posts")
    a.add_where_hash(name: "foo")
    a.limit = 10
    b = described_class.new(table: "posts")
    b.add_where_hash(name: "foo")
    b.limit = 10
    expect(a).to eq(b)
  end
end
