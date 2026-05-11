require "spec_helper"

RSpec.describe Reins::Core::Generators::PortGenerator do
  describe "in app scope (driven default)" do
    let(:bp) { described_class.new("payment_gateway", scope: :app).blueprint }

    it "writes the port file under app/ports/<name>.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("app/ports/payment_gateway.rb")
    end

    it "writes a port spec under spec/ports/<name>_spec.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("spec/ports/payment_gateway_spec.rb")
    end

    it "renders 'module PaymentGateway' extending Reins::Port as :driven" do
      port = bp.files.find { |path, _| path == "app/ports/payment_gateway.rb" }.last
      expect(port).to include('extend Reins::Port')
      expect(port).to include('direction :driven')
      expect(port).to match(/module PaymentGateway\b/)
    end

    it "the spec stub asserts the port has direction and a frozen CONTRACT" do
      spec = bp.files.find { |path, _| path == "spec/ports/payment_gateway_spec.rb" }.last
      expect(spec).to include("PaymentGateway::CONTRACT")
      expect(spec).to include(":driven")
    end

    it "has no executable entries" do
      expect(bp.executables).to be_empty
    end
  end

  describe "in app scope with --driving" do
    let(:bp) { described_class.new("inbound_webhook", direction: :driving, scope: :app).blueprint }

    it "writes the port file under app/ports/<name>.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("app/ports/inbound_webhook.rb")
    end

    it "declares direction :driving" do
      port = bp.files.find { |path, _| path == "app/ports/inbound_webhook.rb" }.last
      expect(port).to include('direction :driving')
    end
  end

  describe "in lib scope" do
    let(:bp) { described_class.new("widget_store", scope: :lib).blueprint }

    it "writes the port under lib/reins/ports/<direction>/<name>.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("lib/reins/ports/driven/widget_store.rb")
    end

    it "writes the port spec under spec/reins/ports/<direction>/<name>_spec.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("spec/reins/ports/driven/widget_store_spec.rb")
    end

    it "nests the module under Reins::Ports::Driven" do
      port = bp.files.find { |path, _| path == "lib/reins/ports/driven/widget_store.rb" }.last
      expect(port).to include("module Reins")
      expect(port).to include("module Ports")
      expect(port).to include("module Driven")
      expect(port).to match(/module WidgetStore\b/)
    end
  end

  describe "name normalization" do
    it "accepts CamelCase, snake_case, and kebab-case" do
      %w[PaymentGateway payment_gateway payment-gateway].each do |input|
        bp = described_class.new(input, scope: :app).blueprint
        paths = bp.files.map(&:first)
        expect(paths).to include("app/ports/payment_gateway.rb"),
                         "input #{input.inspect} did not normalize"
        port = bp.files.find { |p, _| p == "app/ports/payment_gateway.rb" }.last
        expect(port).to match(/module PaymentGateway\b/),
                        "input #{input.inspect} did not produce module PaymentGateway"
      end
    end
  end
end
