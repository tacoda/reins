require "spec_helper"

RSpec.describe Reins::Profile do
  describe ".names" do
    it "lists the registered profiles sorted alphabetically" do
      expect(described_class.names).to eq(%i[slim standard test])
    end
  end

  describe ".fetch" do
    it "returns a Hash with :gems and :adapters keys" do
      profile = described_class.fetch(:standard)
      expect(profile).to be_a(Hash)
      expect(profile.keys).to contain_exactly(:gems, :adapters)
    end

    it "raises ArgumentError on unknown profile, listing available ones" do
      expect { described_class.fetch(:nope) }
        .to raise_error(ArgumentError, /unknown profile.*slim.*standard/m)
    end
  end

  describe ":standard profile" do
    let(:profile) { described_class.fetch(:standard) }

    it "pins the gems each standard adapter needs" do
      expect(profile[:gems]).to include("reins-web", "puma", "sqlite3", "erubis", "zeitwerk", "rackup")
    end

    it "wires every adapter slot the framework offers" do
      expect(profile[:adapters].keys).to include(
        :repository, :schema_inspector, :schema_migrator,
        :template_store, :template_engine,
        :file_system, :server, :process_runner,
        :env_reader, :clock, :autoloader
      )
    end

    it "each adapter entry is a Proc that, called, returns the wired instance" do
      profile[:adapters].each_value do |entry|
        expect(entry).to respond_to(:call)
      end
    end
  end

  describe ":slim profile" do
    let(:profile) { described_class.fetch(:slim) }

    it "pins only reins-web and rackup (plus dev gems)" do
      expect(profile[:gems]).to contain_exactly("reins-web", "rackup")
    end

    it "wires no adapters — every slot is left explicitly nil" do
      expect(profile[:adapters]).to eq({})
    end
  end

  describe ":test profile" do
    let(:profile) { described_class.fetch(:test) }

    it "uses in-memory adapters where available" do
      repository = profile[:adapters][:repository].call
      expect(repository).to be_a(Reins::Adapters::Driven::Memory::Repository)
    end
  end
end
