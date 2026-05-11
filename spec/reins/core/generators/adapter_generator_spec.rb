require "spec_helper"

RSpec.describe Reins::Core::Generators::AdapterGenerator do
  describe "in app scope, driven adapter" do
    let(:port_module) do
      Module.new do
        extend Reins::Port

        direction :driven
        contract charge: 2, refund: 1
      end
    end

    let(:bp) do
      described_class.new(
        "stripe",
        port_module: port_module,
        port_module_name: "PaymentGateway",
        port_require: "payment_gateway",
        direction: :driven,
        scope: :app
      ).blueprint
    end

    it "writes the adapter to app/adapters/<name>.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("app/adapters/stripe.rb")
    end

    it "writes an adapter spec to spec/adapters/<name>_spec.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("spec/adapters/stripe_spec.rb")
    end

    it "the adapter includes the port module" do
      content = bp.files.find { |path, _| path == "app/adapters/stripe.rb" }.last
      expect(content).to include("include PaymentGateway")
    end

    it "defines every method from the port's CONTRACT, raising NotImplementedError" do
      content = bp.files.find { |path, _| path == "app/adapters/stripe.rb" }.last
      expect(content).to match(/def charge\(_arg0, _arg1\)/)
      expect(content).to match(/def refund\(_arg0\)/)
      expect(content.scan('raise NotImplementedError').size).to eq(2)
    end

    it "the spec asserts the adapter responds to every method in CONTRACT" do
      spec = bp.files.find { |path, _| path == "spec/adapters/stripe_spec.rb" }.last
      expect(spec).to include("PaymentGateway::CONTRACT.each_key")
      expect(spec).to include("respond_to")
    end
  end

  describe "in lib scope, driven adapter" do
    let(:port_module) { Reins::Ports::Driven::Clock }

    let(:bp) do
      described_class.new(
        "system",
        port_module: port_module,
        port_module_name: "Reins::Ports::Driven::Clock",
        port_require: "reins/ports/driven/clock",
        direction: :driven,
        scope: :lib
      ).blueprint
    end

    it "writes the adapter under lib/reins/adapters/driven/<name>.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("lib/reins/adapters/driven/system.rb")
    end

    it "writes the adapter spec under spec/reins/adapters/driven/<name>_spec.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("spec/reins/adapters/driven/system_spec.rb")
    end

    it "nests the class under Reins::Adapters::Driven and includes the full port module name" do
      content = bp.files.find { |path, _| path == "lib/reins/adapters/driven/system.rb" }.last
      expect(content).to include("module Reins")
      expect(content).to include("module Adapters")
      expect(content).to include("module Driven")
      expect(content).to include("include Reins::Ports::Driven::Clock")
    end
  end

  describe "driving adapter" do
    let(:bp) do
      described_class.new(
        "webhook",
        port_module: nil,
        port_module_name: "InboundWebhook",
        port_require: "inbound_webhook",
        direction: :driving,
        scope: :app
      ).blueprint
    end

    it "writes the adapter to app/adapters/<name>.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("app/adapters/webhook.rb")
    end

    it "does NOT include the port module (driving adapters use the port, they don't implement it)" do
      content = bp.files.find { |path, _| path == "app/adapters/webhook.rb" }.last
      expect(content).not_to include("include InboundWebhook")
    end

    it "takes a port-implementing app in its constructor" do
      content = bp.files.find { |path, _| path == "app/adapters/webhook.rb" }.last
      expect(content).to include("def initialize(app)")
      expect(content).to include("@app = app")
    end

    it "the spec stub references the port and instantiates the adapter with a fake app" do
      spec = bp.files.find { |path, _| path == "spec/adapters/webhook_spec.rb" }.last
      expect(spec).to include("Webhook")
    end
  end
end
