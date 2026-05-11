require "spec_helper"

RSpec.describe Reins::Adapters::Driven::Puma::Server do
  let(:adapter) { described_class.new }

  it "includes the Server port" do
    expect(described_class.include?(Reins::Ports::Driven::Server)).to be(true)
  end

  it "responds to every method on the Server port contract" do
    Reins::Ports::Driven::Server::CONTRACT.each_key do |name|
      expect(adapter).to respond_to(name), "missing #{name} on Puma::Server"
    end
  end

  it "is constructed without arguments" do
    expect { described_class.new }.not_to raise_error
  end
end
