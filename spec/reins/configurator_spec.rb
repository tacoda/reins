require "spec_helper"
require "tmpdir"

RSpec.describe Reins::Configurator do
  let(:adapters_map) { {} }
  let(:configurator) { described_class.new(adapters_map) }

  describe "#apply" do
    it "stores instances as-is" do
      clock = Reins::Adapters::Driven::System::Clock.new
      configurator.apply(clock: clock)
      expect(adapters_map[:clock]).to be(clock)
    end

    it "calls Procs and stores the result" do
      configurator.apply(clock: -> { Reins::Adapters::Driven::Memory::Clock.new })
      expect(adapters_map[:clock]).to be_a(Reins::Adapters::Driven::Memory::Clock)
    end

    it "instantiates Classes with no-arg new" do
      configurator.apply(clock: Reins::Adapters::Driven::System::Clock)
      expect(adapters_map[:clock]).to be_a(Reins::Adapters::Driven::System::Clock)
    end

    it "merges into the existing map (override semantics)" do
      first = Reins::Adapters::Driven::System::Clock.new
      configurator.apply(clock: first)
      second = Reins::Adapters::Driven::Memory::Clock.new
      configurator.apply(clock: second)
      expect(adapters_map[:clock]).to be(second)
    end
  end

  describe "#load" do
    it "reads a Ruby file whose last expression is a Hash and applies it" do
      Dir.mktmpdir do |tmp|
        path = File.join(tmp, "adapters.rb")
        File.write(path, <<~RUBY)
          {
            clock: -> { Reins::Adapters::Driven::Memory::Clock.new }
          }
        RUBY

        configurator.load(path)
        expect(adapters_map[:clock]).to be_a(Reins::Adapters::Driven::Memory::Clock)
      end
    end

    it "raises a descriptive error when the file does not return a Hash" do
      Dir.mktmpdir do |tmp|
        path = File.join(tmp, "bad.rb")
        File.write(path, "42")
        expect { configurator.load(path) }
          .to raise_error(/must return a Hash/i)
      end
    end
  end

  describe ".from_profile" do
    it "applies the named profile's adapter Hash" do
      map = {}
      described_class.from_profile(:standard, into: map)
      expect(map.keys).to include(:repository, :clock, :server)
    end

    it ":slim leaves the map empty" do
      map = {}
      described_class.from_profile(:slim, into: map)
      expect(map).to eq({})
    end
  end
end
