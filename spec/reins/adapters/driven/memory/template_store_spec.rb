require "spec_helper"

RSpec.describe Reins::Adapters::Driven::Memory::TemplateStore do
  let(:store) do
    described_class.new(
      "posts/show" => "<%= @title %>",
      "layouts/application" => "<wrap><%= yield %></wrap>"
    )
  end

  it "includes the TemplateStore port" do
    expect(described_class.include?(Reins::Ports::Driven::TemplateStore)).to be(true)
  end

  it "responds to every method on the TemplateStore port contract" do
    Reins::Ports::Driven::TemplateStore::CONTRACT.each_key do |name|
      expect(store).to respond_to(name), "missing #{name} on Memory::TemplateStore"
    end
  end

  it "#exist? returns true for stored templates" do
    expect(store.exist?("posts/show")).to be(true)
  end

  it "#exist? returns false for unknown templates" do
    expect(store.exist?("nope")).to be(false)
  end

  it "#read returns the stored source" do
    expect(store.read("posts/show")).to eq("<%= @title %>")
  end

  it "#read raises Errno::ENOENT on a missing template" do
    expect { store.read("nope") }.to raise_error(Errno::ENOENT)
  end
end
