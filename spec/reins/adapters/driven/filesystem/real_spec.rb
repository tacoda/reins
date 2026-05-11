require "spec_helper"
require "tmpdir"

RSpec.describe Reins::Adapters::Driven::Filesystem::Real do
  let(:fs) { described_class.new }

  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) { example.run }
    end
  end

  it "includes the FileSystem port" do
    expect(described_class.include?(Reins::Ports::Driven::FileSystem)).to be(true)
  end

  it "responds to every method on the FileSystem port contract" do
    Reins::Ports::Driven::FileSystem::CONTRACT.each_key do |name|
      expect(fs).to respond_to(name), "missing #{name} on Filesystem::Real"
    end
  end

  it "creates parent directories on #write" do
    fs.write("a/b/c.txt", "hello")
    expect(File.read("a/b/c.txt")).to eq("hello")
  end

  it "round-trips content via #read" do
    fs.write("a.txt", "hello")
    expect(fs.read("a.txt")).to eq("hello")
  end

  it "makes a file executable via chmod \"+x\"" do
    fs.write("bin/setup", "#!/bin/sh\n")
    fs.chmod("+x", "bin/setup")
    expect(File.executable?("bin/setup")).to be(true)
  end

  it "answers #exist? against real disk state" do
    expect(fs.exist?("nope.txt")).to be(false)
    fs.write("yes.txt", "x")
    expect(fs.exist?("yes.txt")).to be(true)
  end

  it "globs real disk paths" do
    fs.write("a/one.rb", "")
    fs.write("a/two.rb", "")
    fs.write("a/three.txt", "")
    expect(fs.glob("a/*.rb").sort).to eq(["a/one.rb", "a/two.rb"])
  end

  it "removes files idempotently via #rm_f" do
    fs.write("a.txt", "x")
    fs.rm_f("a.txt")
    expect(File.exist?("a.txt")).to be(false)
    expect { fs.rm_f("a.txt") }.not_to raise_error
  end

  it "returns mtime for an existing file" do
    fs.write("a.txt", "x")
    expect(fs.mtime("a.txt")).to be_a(Time)
  end
end
