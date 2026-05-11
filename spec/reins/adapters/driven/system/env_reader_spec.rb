require "spec_helper"

RSpec.describe Reins::Adapters::Driven::System::EnvReader do
  let(:adapter) { described_class.new }

  it "includes the EnvReader port" do
    expect(described_class.include?(Reins::Ports::Driven::EnvReader)).to be(true)
  end

  it "responds to every method on the EnvReader port contract" do
    Reins::Ports::Driven::EnvReader::CONTRACT.each_key do |name|
      expect(adapter).to respond_to(name), "missing #{name} on System::EnvReader"
    end
  end

  it "#[] reads the matching ENV value" do
    expect(adapter["PATH"]).to eq(ENV.fetch("PATH"))
  end

  it "#fetch returns the default when the key is unset" do
    expect(adapter.fetch("REINS_SHOULD_BE_UNSET_KEY_xyz_123", "fallback")).to eq("fallback")
  end

  it "#fetch returns the actual value when set" do
    expect(adapter.fetch("PATH", "nope")).to eq(ENV.fetch("PATH"))
  end

  it "#key? reflects ENV.key?" do
    expect(adapter.key?("PATH")).to be(true)
    expect(adapter.key?("REINS_SHOULD_BE_UNSET_KEY_xyz_123")).to be(false)
  end
end
