require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Reins::Adapters::Driven::Filesystem::TemplateStore do
  let(:store) { described_class.new("app/views") }

  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) { example.run }
    end
  end

  it "includes the TemplateStore port" do
    expect(described_class.include?(Reins::Ports::Driven::TemplateStore)).to be(true)
  end

  it "responds to every method on the TemplateStore port contract" do
    Reins::Ports::Driven::TemplateStore::CONTRACT.each_key do |name|
      expect(store).to respond_to(name), "missing #{name} on Filesystem::TemplateStore"
    end
  end

  it "#exist? returns true for an existing template" do
    FileUtils.mkdir_p("app/views/posts")
    File.write("app/views/posts/show.html.erb", "inner")
    expect(store.exist?("posts/show")).to be(true)
  end

  it "#exist? returns false for a missing template" do
    expect(store.exist?("nope/missing")).to be(false)
  end

  it "#read returns the file content" do
    FileUtils.mkdir_p("app/views/posts")
    File.write("app/views/posts/show.html.erb", "inner")
    expect(store.read("posts/show")).to eq("inner")
  end

  it "#read raises Errno::ENOENT on a missing template" do
    expect { store.read("nope/missing") }.to raise_error(Errno::ENOENT)
  end
end
