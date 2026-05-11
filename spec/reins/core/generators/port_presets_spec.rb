require "spec_helper"

RSpec.describe Reins::Core::Generators::PortPresets do
  describe ".names" do
    it "lists every registered preset sorted alphabetically" do
      expect(described_class.names).to eq(
        %i[clock env erubis filesystem memory puma rack sqlite thor]
      )
    end
  end

  describe ".descriptions" do
    it "provides a non-empty description for each preset" do
      described_class.names.each do |name|
        expect(described_class.descriptions[name]).to be_a(String)
        expect(described_class.descriptions[name]).not_to be_empty
      end
    end
  end

  describe ".fetch" do
    it "raises ArgumentError on unknown presets, listing the valid ones" do
      expect { described_class.fetch(:nope, scope: :lib) }
        .to raise_error(ArgumentError, /unknown preset.*rack.*sqlite/m)
    end

    it ":rack returns a Blueprint with the Rack driving adapter files" do
      bp = described_class.fetch(:rack, scope: :lib)
      paths = bp.files.map(&:first)
      expect(paths).to include(a_string_matching(%r{lib/reins/adapters/driving/rack/}))
    end

    it ":sqlite returns a Blueprint covering Repository, SchemaInspector, and SchemaMigrator adapters" do
      bp = described_class.fetch(:sqlite, scope: :lib)
      paths = bp.files.map(&:first).join("\n")
      expect(paths).to match(%r{lib/reins/adapters/driven/sqlite/repository\.rb})
      expect(paths).to match(%r{lib/reins/adapters/driven/sqlite/schema_inspector\.rb})
      expect(paths).to match(%r{lib/reins/adapters/driven/sqlite/schema_migrator\.rb})
    end

    it ":memory returns in-memory test adapters" do
      bp = described_class.fetch(:memory, scope: :lib)
      paths = bp.files.map(&:first).join("\n")
      expect(paths).to match(%r{lib/reins/adapters/driven/memory/repository\.rb})
    end

    it ":puma returns the Server port adapter" do
      bp = described_class.fetch(:puma, scope: :lib)
      paths = bp.files.map(&:first).join("\n")
      expect(paths).to match(%r{lib/reins/adapters/driven/puma/server\.rb})
    end

    it ":filesystem returns the FileSystem adapter" do
      bp = described_class.fetch(:filesystem, scope: :lib)
      paths = bp.files.map(&:first).join("\n")
      expect(paths).to match(%r{lib/reins/adapters/driven/filesystem/real\.rb})
    end

    it ":erubis returns the TemplateEngine adapter" do
      bp = described_class.fetch(:erubis, scope: :lib)
      paths = bp.files.map(&:first).join("\n")
      expect(paths).to match(%r{lib/reins/adapters/driven/erubis/template_engine\.rb})
    end

    it ":clock returns the System::Clock adapter" do
      bp = described_class.fetch(:clock, scope: :lib)
      paths = bp.files.map(&:first).join("\n")
      expect(paths).to match(%r{lib/reins/adapters/driven/system/clock\.rb})
    end

    it ":env returns the System::EnvReader adapter" do
      bp = described_class.fetch(:env, scope: :lib)
      paths = bp.files.map(&:first).join("\n")
      expect(paths).to match(%r{lib/reins/adapters/driven/system/env_reader\.rb})
    end

    it ":thor returns the Thor::Cli driving adapter" do
      bp = described_class.fetch(:thor, scope: :lib)
      paths = bp.files.map(&:first).join("\n")
      expect(paths).to match(%r{lib/reins/adapters/driving/thor/cli\.rb})
    end
  end
end
