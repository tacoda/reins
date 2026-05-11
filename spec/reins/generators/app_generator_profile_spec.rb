require "spec_helper"

RSpec.describe Reins::Generators::AppGenerator do
  describe "default (:standard) profile" do
    let(:bp) { described_class.new("myapp").blueprint }
    let(:gemfile) { bp.files.find { |path, _| path == "Gemfile" }.last }

    it "pins puma" do
      expect(gemfile).to include('gem "puma"')
    end

    it "pins sqlite3" do
      expect(gemfile).to include('gem "sqlite3"')
    end

    it "pins erubis" do
      expect(gemfile).to include('gem "erubis"')
    end

    it "pins zeitwerk" do
      expect(gemfile).to include('gem "zeitwerk"')
    end

    it "pins rackup" do
      expect(gemfile).to include('gem "rackup"')
    end
  end

  describe ":slim profile" do
    let(:bp) { described_class.new("myapp", profile: :slim).blueprint }
    let(:gemfile) { bp.files.find { |path, _| path == "Gemfile" }.last }

    it "pins reins-web" do
      expect(gemfile).to include('gem "reins-web"')
    end

    it "pins rackup" do
      expect(gemfile).to include('gem "rackup"')
    end

    it "does NOT pin puma" do
      expect(gemfile).not_to include('gem "puma"')
    end

    it "does NOT pin sqlite3" do
      expect(gemfile).not_to include('gem "sqlite3"')
    end

    it "does NOT pin erubis" do
      expect(gemfile).not_to include('gem "erubis"')
    end
  end
end
