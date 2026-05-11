require "spec_helper"

RSpec.describe Reins::Adapters::Driven::Memory::FileSystem do
  let(:fs) { described_class.new }

  it "includes the FileSystem port" do
    expect(described_class.include?(Reins::Ports::Driven::FileSystem)).to be(true)
  end

  it "responds to every method on the FileSystem port contract" do
    Reins::Ports::Driven::FileSystem::CONTRACT.each_key do |name|
      expect(fs).to respond_to(name), "missing #{name} on Memory::FileSystem"
    end
  end

  it "round-trips written content via #read" do
    fs.write("a/b.txt", "hello")
    expect(fs.read("a/b.txt")).to eq("hello")
  end

  it "raises Errno::ENOENT on #read of a missing path" do
    expect { fs.read("missing.txt") }.to raise_error(Errno::ENOENT)
  end

  it "reports #exist? before and after writing" do
    expect(fs.exist?("a.txt")).to be(false)
    fs.write("a.txt", "x")
    expect(fs.exist?("a.txt")).to be(true)
  end

  it "treats #mkdir_p as a no-op that always succeeds" do
    expect { fs.mkdir_p("any/nested/dir") }.not_to raise_error
  end

  it "records executable flags set by #chmod" do
    fs.write("bin/setup", "#!/bin/sh\n")
    fs.chmod("+x", "bin/setup")
    expect(fs.executable?("bin/setup")).to be(true)
  end

  it "globs matching paths" do
    fs.write("a/one.rb", "")
    fs.write("a/two.rb", "")
    fs.write("a/three.txt", "")
    expect(fs.glob("a/*.rb").sort).to eq(["a/one.rb", "a/two.rb"])
  end

  it "removes entries with #rm_f and is idempotent" do
    fs.write("a.txt", "x")
    fs.rm_f("a.txt")
    expect(fs.exist?("a.txt")).to be(false)
    expect { fs.rm_f("a.txt") }.not_to raise_error
  end

  it "returns a deterministic mtime per write" do
    fs.write("a.txt", "x")
    first = fs.mtime("a.txt")
    fs.write("a.txt", "y")
    second = fs.mtime("a.txt")
    expect(second).to be >= first
  end
end
