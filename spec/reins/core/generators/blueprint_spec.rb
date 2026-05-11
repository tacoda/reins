require "spec_helper"

RSpec.describe Reins::Core::Generators::Blueprint do
  it "is empty when constructed with no entries" do
    expect(described_class.new).to be_empty
  end

  it "stores file entries retrievable via #files" do
    bp = described_class.new
    bp.add_file("a.txt", "hello")
    bp.add_file("b.txt", "world")

    expect(bp.files).to eq([
                             ["a.txt", "hello"],
                             ["b.txt", "world"]
                           ])
  end

  it "stores executable paths retrievable via #executables" do
    bp = described_class.new
    bp.add_executable("bin/setup")

    expect(bp.executables).to eq(["bin/setup"])
  end

  it "is not empty after adding any entry" do
    bp = described_class.new
    bp.add_file("a.txt", "x")
    expect(bp.empty?).to be(false)
  end

  it "merges two blueprints into a new one" do
    a = described_class.new
    a.add_file("a.txt", "1")
    a.add_executable("bin/a")

    b = described_class.new
    b.add_file("b.txt", "2")
    b.add_executable("bin/b")

    merged = a.merge(b)

    expect(merged.files).to eq([["a.txt", "1"], ["b.txt", "2"]])
    expect(merged.executables).to eq(["bin/a", "bin/b"])
  end

  it "returns the same entries from #files on repeated calls (no shared mutation)" do
    bp = described_class.new
    bp.add_file("a.txt", "x")
    first = bp.files
    second = bp.files
    expect(first).to eq(second)
    expect(first).not_to equal(second.object_id)
  end

  it "compares equal when entries match" do
    a = described_class.new
    a.add_file("a.txt", "x")
    a.add_executable("bin/a")

    b = described_class.new
    b.add_file("a.txt", "x")
    b.add_executable("bin/a")

    expect(a).to eq(b)
  end

  it "compares unequal when entries differ" do
    a = described_class.new
    a.add_file("a.txt", "x")

    b = described_class.new
    b.add_file("a.txt", "y")

    expect(a).not_to eq(b)
  end
end
