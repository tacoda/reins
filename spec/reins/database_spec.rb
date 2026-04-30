require "spec_helper"
require "tmpdir"

RSpec.describe Reins::Database do
  around do |example|
    Dir.mktmpdir do |tmp|
      @tmp = tmp
      original = Reins::Database.path
      example.run
      Reins::Database.reset!
      Reins::Database.path = original if original
    end
  end

  it "defaults the database path to test.db for backward compatibility" do
    Reins::Database.reset!
    expect(Reins::Database.path).to eq("test.db")
  end

  it "allows the database path to be configured" do
    custom = File.join(@tmp, "custom.db")
    Reins::Database.path = custom
    expect(Reins::Database.path).to eq(custom)
  end

  it "memoizes the SQLite3 connection across calls" do
    Reins::Database.path = File.join(@tmp, "memo.db")
    first_call = Reins::Database.connection
    expect(Reins::Database.connection).to be(first_call)
  end

  it "opens a new connection after reset!" do
    Reins::Database.path = File.join(@tmp, "first.db")
    first = Reins::Database.connection
    Reins::Database.reset!
    Reins::Database.path = File.join(@tmp, "second.db")
    expect(Reins::Database.connection).not_to be(first)
  end
end
