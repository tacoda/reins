require "spec_helper"

RSpec.describe Reins::Core::Generators::UseCaseGenerator do
  describe "default deps" do
    let(:bp) { described_class.new("CreatePost").blueprint }

    it "writes the use case under app/use_cases/<name>.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("app/use_cases/create_post.rb")
    end

    it "writes a spec under spec/use_cases/<name>_spec.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("spec/use_cases/create_post_spec.rb")
    end

    it "defines a class named CreatePost" do
      content = bp.files.find { |path, _| path == "app/use_cases/create_post.rb" }.last
      expect(content).to match(/class CreatePost\b/)
    end

    it "the constructor takes repository: and clock: by default, defaulting to Reins.application.adapter(...)" do
      content = bp.files.find { |path, _| path == "app/use_cases/create_post.rb" }.last
      expect(content).to match(/def initialize\(.*repository:.*\)/m)
      expect(content).to match(/def initialize\(.*clock:.*\)/m)
      expect(content).to include("Reins.application.adapter(:repository)")
    end

    it "the use case exposes a #call entry point" do
      content = bp.files.find { |path, _| path == "app/use_cases/create_post.rb" }.last
      expect(content).to include("def call")
    end

    it "the spec wires Memory adapters via Application.new(profile: :test)" do
      content = bp.files.find { |path, _| path == "spec/use_cases/create_post_spec.rb" }.last
      expect(content).to match(/Reins::Application\.new\([^)]*profile:\s*:test/m)
      expect(content).to include("Memory::Repository")
    end
  end

  describe "custom deps" do
    let(:bp) { described_class.new("ChargePayment", %w[payment_gateway clock]).blueprint }

    it "the constructor takes only the named deps" do
      content = bp.files.find { |path, _| path == "app/use_cases/charge_payment.rb" }.last
      expect(content).to match(/def initialize\(.*payment_gateway:.*clock:.*\)/m)
      expect(content).not_to match(/repository:/)
      expect(content).to include("Reins.application.adapter(:payment_gateway)")
    end
  end

  describe "name normalization" do
    it "accepts CamelCase, snake_case, kebab-case" do
      %w[CreatePost create_post create-post].each do |input|
        bp = described_class.new(input).blueprint
        paths = bp.files.map(&:first)
        expect(paths).to include("app/use_cases/create_post.rb")
      end
    end
  end
end
