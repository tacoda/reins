require "spec_helper"

RSpec.describe Reins::Application do
  describe "#adapter" do
    it "returns the wired instance for a configured key" do
      app = described_class.new(profile: :test)
      expect(app.adapter(:repository)).to be_a(Reins::Adapters::Driven::Memory::Repository)
    end

    it "raises Reins::AdapterMissing with a descriptive message when the key is unset" do
      app = described_class.new(profile: :slim)
      expect { app.adapter(:repository) }
        .to raise_error(Reins::AdapterMissing, /no repository adapter configured.*slim/m)
    end

    it "lists the keys that ARE wired in the error message" do
      app = described_class.new(profile: :slim, adapters: {
                                  clock: Reins::Adapters::Driven::Memory::Clock.new
                                })
      expect { app.adapter(:repository) }
        .to raise_error(Reins::AdapterMissing, /Available adapters.*clock/m)
    end
  end

  describe "#validate_adapters!" do
    it "passes when every wired adapter responds to its port's contract" do
      app = described_class.new(profile: :standard)
      expect { app.validate_adapters! }.not_to raise_error
    end

    it "raises Reins::ContractViolation when a wired adapter is missing a contract method" do
      broken = Object.new
      def broken.find_all(_query) = []
      # intentionally missing #insert, #update, ...

      expect do
        described_class.new(profile: :slim, adapters: { repository: broken })
      end.to raise_error(Reins::ContractViolation, /repository.*does not respond to/i)
    end

    it "can be opted out with validate: false" do
      broken = Object.new
      expect do
        described_class.new(profile: :slim, adapters: { repository: broken }, validate: false)
      end.not_to raise_error
    end
  end

  describe "#describe_adapters" do
    it "returns a multi-line string listing the profile and each wired adapter" do
      app = described_class.new(profile: :test)
      output = app.describe_adapters

      expect(output).to include("Profile: test")
      expect(output).to include("repository")
      expect(output).to include("Reins::Adapters::Driven::Memory::Repository")
    end

    it "shows an empty graph for the :slim profile" do
      app = described_class.new(profile: :slim)
      output = app.describe_adapters

      expect(output).to include("Profile: slim")
      expect(output).to match(/no adapters wired/i)
    end
  end
end
