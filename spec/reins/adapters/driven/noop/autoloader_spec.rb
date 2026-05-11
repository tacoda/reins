require "spec_helper"

RSpec.describe Reins::Adapters::Driven::Noop::Autoloader do
  let(:adapter) { described_class.new }

  it "includes the Autoloader port" do
    expect(described_class.include?(Reins::Ports::Driven::Autoloader)).to be(true)
  end

  it "responds to every method on the Autoloader port contract" do
    Reins::Ports::Driven::Autoloader::CONTRACT.each_key do |name|
      expect(adapter).to respond_to(name), "missing #{name} on Noop::Autoloader"
    end
  end

  it "#setup records the given paths" do
    adapter.setup(%w[a b])
    expect(adapter.setup_paths).to eq(%w[a b])
  end

  it "#eager_load! / #reload! record their calls" do
    adapter.eager_load!
    expect(adapter.eager_loaded?).to be(true)

    adapter.reload!
    expect(adapter.reloaded?).to be(true)
  end

  it "#reset! clears recorded state" do
    adapter.setup(["a"])
    adapter.eager_load!
    adapter.reset!
    expect(adapter.setup_paths).to eq([])
    expect(adapter.eager_loaded?).to be(false)
  end
end
