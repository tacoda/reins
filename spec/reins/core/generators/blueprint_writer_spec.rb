require "spec_helper"

RSpec.describe Reins::Core::Generators::BlueprintWriter do
  let(:fs) { Reins::Adapters::Driven::Memory::FileSystem.new }
  let(:writer) { described_class.new(fs) }

  it "writes each blueprint file under the root" do
    bp = Reins::Core::Generators::Blueprint.new
    bp.add_file("Gemfile", "source 'x'")
    bp.add_file("config/app.rb", "module X; end")

    writer.write(bp, root: "myapp")

    expect(fs.read("myapp/Gemfile")).to eq("source 'x'")
    expect(fs.read("myapp/config/app.rb")).to eq("module X; end")
  end

  it "joins paths with no root when root is nil" do
    bp = Reins::Core::Generators::Blueprint.new
    bp.add_file("a.txt", "x")

    writer.write(bp)

    expect(fs.read("a.txt")).to eq("x")
  end

  it "marks executable entries via chmod \"+x\"" do
    bp = Reins::Core::Generators::Blueprint.new
    bp.add_file("bin/setup", "#!/bin/sh\n")
    bp.add_executable("bin/setup")

    writer.write(bp, root: "myapp")

    expect(fs.executable?("myapp/bin/setup")).to be(true)
  end

  it "is a no-op when the blueprint is empty" do
    bp = Reins::Core::Generators::Blueprint.new
    expect { writer.write(bp, root: "myapp") }.not_to raise_error
    expect(fs.glob("**/*")).to eq([])
  end
end
