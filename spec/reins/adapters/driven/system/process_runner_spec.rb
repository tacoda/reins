require "spec_helper"

RSpec.describe Reins::Adapters::Driven::System::ProcessRunner do
  let(:adapter) { described_class.new }

  it "includes the ProcessRunner port" do
    expect(described_class.include?(Reins::Ports::Driven::ProcessRunner)).to be(true)
  end

  it "responds to every method on the ProcessRunner port contract" do
    Reins::Ports::Driven::ProcessRunner::CONTRACT.each_key do |name|
      expect(adapter).to respond_to(name), "missing #{name} on System::ProcessRunner"
    end
  end

  it "#system returns true on success" do
    expect(adapter.system("true")).to be(true)
  end

  it "#system returns false on a non-zero exit" do
    expect(adapter.system("false")).to be(false)
  end

  it "#system accepts argv-array form" do
    expect(adapter.system("/bin/echo", "hi")).to be(true)
  end
end
