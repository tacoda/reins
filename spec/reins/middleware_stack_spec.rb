require "spec_helper"

# Stub middleware classes used by the stack specs below.
class Mw1
  def initialize(app, *) = (@app = app)
  def call(env) = @app.call(env)
end

class Mw2
  def initialize(app, *) = (@app = app)
  def call(env) = @app.call(env)
end

class Mw3
  def initialize(app, *) = (@app = app)
  def call(env) = @app.call(env)
end

RSpec.describe Reins::MiddlewareStack do
  subject(:stack) { described_class.new }

  it "use(klass, *args, &block) appends to the stack" do
    stack.use(Mw1, "x", "y")
    expect(stack.to_a).to eq([[Mw1, %w[x y], nil]])
  end

  it "insert_before(target, klass) inserts immediately before target" do
    stack.use(Mw1)
    stack.use(Mw2)
    stack.insert_before(Mw2, Mw3)
    expect(stack.to_a.map(&:first)).to eq([Mw1, Mw3, Mw2])
  end

  it "insert_after(target, klass) inserts immediately after target" do
    stack.use(Mw1)
    stack.use(Mw2)
    stack.insert_after(Mw1, Mw3)
    expect(stack.to_a.map(&:first)).to eq([Mw1, Mw3, Mw2])
  end

  it "delete(klass) removes the entry" do
    stack.use(Mw1)
    stack.use(Mw2)
    stack.delete(Mw1)
    expect(stack.to_a.map(&:first)).to eq([Mw2])
  end

  it "each yields [klass, args, block] tuples in order" do
    block = proc {}
    stack.use(Mw1, 1, 2)
    stack.use(Mw2, &block)

    yielded = stack.map { |klass, args, blk| [klass, args, blk] }

    expect(yielded).to eq([[Mw1, [1, 2], nil], [Mw2, [], block]])
  end
end
