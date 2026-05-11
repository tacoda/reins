require "spec_helper"

DRIVING_PORTS = %w[HttpApp CommandInvoker].freeze
DRIVEN_PORTS = %w[
  Repository
  SchemaInspector
  SchemaMigrator
  TemplateStore
  TemplateEngine
  FileSystem
  ProcessRunner
  Server
  EnvReader
  Clock
].freeze

RSpec.describe "ports catalog" do
  describe "driving ports" do
    DRIVING_PORTS.each do |port|
      it "Reins::Ports::Driving::#{port} is a Module" do
        expect(Reins::Ports::Driving.const_get(port)).to be_a(Module)
      end

      it "Reins::Ports::Driving::#{port} exposes a frozen CONTRACT Hash" do
        port_module = Reins::Ports::Driving.const_get(port)
        expect(port_module::CONTRACT).to be_a(Hash)
        expect(port_module::CONTRACT).to be_frozen
      end
    end
  end

  describe "driven ports" do
    DRIVEN_PORTS.each do |port|
      it "Reins::Ports::Driven::#{port} is a Module" do
        expect(Reins::Ports::Driven.const_get(port)).to be_a(Module)
      end

      it "Reins::Ports::Driven::#{port} exposes a frozen CONTRACT Hash" do
        port_module = Reins::Ports::Driven.const_get(port)
        expect(port_module::CONTRACT).to be_a(Hash)
        expect(port_module::CONTRACT).to be_frozen
      end
    end
  end

  describe "CONTRACT shape" do
    it "every contract entry maps a Symbol method name to an Integer arity" do
      all_ports = DRIVING_PORTS.map { |p| Reins::Ports::Driving.const_get(p) } +
                  DRIVEN_PORTS.map  { |p| Reins::Ports::Driven.const_get(p) }
      all_ports.each do |port|
        port::CONTRACT.each do |name, arity|
          expect(name).to be_a(Symbol), "#{port}: contract key #{name.inspect} must be a Symbol"
          expect(arity).to be_a(Integer), "#{port}: contract value for #{name} must be an Integer"
        end
      end
    end
  end
end
