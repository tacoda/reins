require "spec_helper"

RSpec.describe Reins::Application do
  describe "#adapters" do
    it "defaults to the :standard profile when none is given" do
      app = described_class.new
      expect(app.adapters.keys).to include(:repository, :server, :clock)
    end

    it "loads :slim profile leaving every slot unset" do
      app = described_class.new(profile: :slim)
      expect(app.adapters).to eq({})
    end

    it "loads :test profile with in-memory adapters" do
      app = described_class.new(profile: :test)
      expect(app.adapters[:repository]).to be_a(Reins::Adapters::Driven::Memory::Repository)
      expect(app.adapters[:clock]).to be_a(Reins::Adapters::Driven::Memory::Clock)
    end

    it "applies explicit overrides on top of the profile" do
      my_clock = Reins::Adapters::Driven::Memory::Clock.new
      app = described_class.new(profile: :standard, adapters: { clock: my_clock })
      expect(app.adapters[:clock]).to be(my_clock)
    end

    it "explicit adapters can override a slim profile to add what you need" do
      app = described_class.new(profile: :slim, adapters: {
                                  clock: Reins::Adapters::Driven::Memory::Clock.new
                                })
      expect(app.adapters[:clock]).to be_a(Reins::Adapters::Driven::Memory::Clock)
      expect(app.adapters).not_to have_key(:server)
    end
  end

  describe "#profile" do
    it "returns the selected profile name" do
      expect(described_class.new(profile: :slim).profile).to eq(:slim)
    end

    it "defaults to :standard" do
      expect(described_class.new.profile).to eq(:standard)
    end
  end

  describe "backward compatibility" do
    it "Application.new with no args still works (existing apps)" do
      expect { described_class.new }.not_to raise_error
    end
  end
end
