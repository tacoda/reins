require "spec_helper"

RSpec.describe Reins::Adapters::Driven::System::Clock do
  let(:adapter) { described_class.new }

  it "includes the Clock port" do
    expect(described_class.include?(Reins::Ports::Driven::Clock)).to be(true)
  end

  it "responds to every method on the Clock port contract" do
    Reins::Ports::Driven::Clock::CONTRACT.each_key do |name|
      expect(adapter).to respond_to(name), "missing #{name} on System::Clock"
    end
  end

  it "#now returns a Time close to wall-clock now" do
    before_time = Time.now
    result = adapter.now
    after_time = Time.now

    expect(result).to be_a(Time)
    expect(result).to be_between(before_time, after_time)
  end
end
