require "spec_helper"

RSpec.describe Reins::Port do
  def fresh_port
    Module.new.tap { |m| m.extend(Reins::Port) }
  end

  describe "#port?" do
    it "returns true on modules that extend Reins::Port" do
      expect(fresh_port.port?).to be(true)
    end
  end

  describe "#direction" do
    it "sets the direction to :driven" do
      port = fresh_port
      port.direction :driven
      expect(port.direction).to eq(:driven)
      expect(port::DIRECTION).to eq(:driven)
    end

    it "sets the direction to :driving" do
      port = fresh_port
      port.direction :driving
      expect(port.direction).to eq(:driving)
      expect(port::DIRECTION).to eq(:driving)
    end

    it "raises ArgumentError on an unknown direction" do
      port = fresh_port
      expect { port.direction :nope }
        .to raise_error(ArgumentError, /unknown direction.*driven.*driving/i)
    end

    it "raises when direction is set twice" do
      port = fresh_port
      port.direction :driven
      expect { port.direction :driving }
        .to raise_error(/direction already set/i)
    end
  end

  describe "#contract" do
    it "sets CONTRACT as a frozen Hash with the declared methods" do
      port = fresh_port
      port.direction :driven
      port.contract(find_all: 1, insert: 2)
      expect(port::CONTRACT).to eq(find_all: 1, insert: 2)
      expect(port::CONTRACT).to be_frozen
    end

    it "raises if direction was not set first" do
      port = fresh_port
      expect { port.contract(foo: 1) }
        .to raise_error(/direction must be set/i)
    end

    it "rejects non-Symbol keys" do
      port = fresh_port
      port.direction :driven
      expect { port.contract("foo" => 1) }
        .to raise_error(ArgumentError, /Symbol/)
    end

    it "rejects non-Integer arities" do
      port = fresh_port
      port.direction :driven
      expect { port.contract(foo: "1") }
        .to raise_error(ArgumentError, /Integer/)
    end

    it "raises when contract is declared twice" do
      port = fresh_port
      port.direction :driven
      port.contract(foo: 1)
      expect { port.contract(bar: 1) }
        .to raise_error(/contract already declared/i)
    end

    it "accepts special method names via Hash literal" do
      port = fresh_port
      port.direction :driven
      port.contract(:[] => 1, :key? => 1)
      expect(port::CONTRACT).to eq(:[] => 1, :key? => 1)
    end
  end

  describe "registry" do
    it "lists every extended module in .all" do
      port = fresh_port
      expect(Reins::Port.all).to include(port)
    end

    it ".driven and .driving filter by declared direction" do
      driven_port = fresh_port
      driven_port.direction :driven
      driving_port = fresh_port
      driving_port.direction :driving

      expect(Reins::Port.driven).to include(driven_port)
      expect(Reins::Port.driving).to include(driving_port)
      expect(Reins::Port.driven).not_to include(driving_port)
    end
  end
end
