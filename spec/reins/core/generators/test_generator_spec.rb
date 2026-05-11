require "spec_helper"

RSpec.describe Reins::Core::Generators::TestGenerator do
  let(:port_module) do
    Module.new do
      extend Reins::Port

      direction :driven
      contract charge: 2, refund: 1
    end
  end

  describe "in app scope" do
    let(:bp) do
      described_class.new(
        port_module: port_module,
        port_module_name: "PaymentGateway",
        port_require: "payment_gateway",
        scope: :app
      ).blueprint
    end

    it "writes a test double under spec/doubles/<name>_double.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("spec/doubles/payment_gateway_double.rb")
    end

    it "writes a use-case spec template under spec/use_cases/<name>_use_case_spec.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("spec/use_cases/payment_gateway_use_case_spec.rb")
    end

    it "the double class includes the port module" do
      content = bp.files.find { |path, _| path == "spec/doubles/payment_gateway_double.rb" }.last
      expect(content).to include("include PaymentGateway")
    end

    it "the double records every method call on its #calls attribute" do
      content = bp.files.find { |path, _| path == "spec/doubles/payment_gateway_double.rb" }.last
      expect(content).to include("attr_reader :calls")
      expect(content).to include("@calls << { method: :charge")
      expect(content).to include("@calls << { method: :refund")
    end

    it "the double accepts configurable return values via returns:" do
      content = bp.files.find { |path, _| path == "spec/doubles/payment_gateway_double.rb" }.last
      expect(content).to include("def initialize(returns: {})")
      expect(content).to include("@returns.fetch(:charge")
    end

    it "the use-case spec template wires the double into Application.new(profile: :test)" do
      content = bp.files.find { |path, _| path == "spec/use_cases/payment_gateway_use_case_spec.rb" }.last
      expect(content).to include("PaymentGatewayDouble.new")
      expect(content).to include("payment_gateway:")
      expect(content).to match(/Reins::Application\.new\([^)]*profile:\s*:test/m)
    end
  end

  describe "in lib scope" do
    let(:port_module) { Reins::Ports::Driven::Clock }

    let(:bp) do
      described_class.new(
        port_module: port_module,
        port_module_name: "Reins::Ports::Driven::Clock",
        port_require: "reins/ports/driven/clock",
        scope: :lib
      ).blueprint
    end

    it "writes the double under spec/reins/doubles/<name>_double.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("spec/reins/doubles/clock_double.rb")
    end

    it "writes the use-case spec under spec/reins/use_cases/<name>_use_case_spec.rb" do
      paths = bp.files.map(&:first)
      expect(paths).to include("spec/reins/use_cases/clock_use_case_spec.rb")
    end
  end
end
