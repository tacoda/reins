require "spec_helper"

RSpec.describe "Reins::Model::Base validations" do
  around do |example|
    setup_test_db
    create_table(:items, "id INTEGER PRIMARY KEY, name TEXT, slug TEXT")
    example.run
  ensure
    teardown_test_db
  end

  let(:item_class) do
    Class.new(Reins::Model::Base) do
      self.table_name = "items"
    end
  end

  it "presence: true adds an error when value is blank" do
    klass = Class.new(item_class) { validates :name, presence: true }
    record = klass.new(name: "")
    expect(record.valid?).to be(false)
    expect(record.errors[:name]).to include("can't be blank")
  end

  it "length: { in: 1..3 } enforces both bounds" do
    klass = Class.new(item_class) { validates :name, length: { in: 1..3 } }

    expect(klass.new(name: "").valid?).to be(false)
    expect(klass.new(name: "abcd").valid?).to be(false)
    expect(klass.new(name: "ab").valid?).to be(true)
  end

  it "format: /regex/ rejects mismatches" do
    klass = Class.new(item_class) { validates :slug, format: /\A[a-z]+\z/ }

    expect(klass.new(slug: "abc").valid?).to be(true)
    expect(klass.new(slug: "Bad-1").valid?).to be(false)
  end

  it "uniqueness: true rejects creating a duplicate" do
    klass = Class.new(item_class) { validates :slug, uniqueness: true }
    klass.create!(slug: "abc")

    duplicate = klass.new(slug: "abc")
    expect(duplicate.valid?).to be(false)
    expect(duplicate.errors[:slug]).to include("has already been taken")
  end

  it "uniqueness allows updating the same record once persisted" do
    klass = Class.new(item_class) { validates :slug, uniqueness: true }
    record = klass.create!(slug: "abc")
    record.name = "renamed"
    expect(record.valid?).to be(true)
    expect(record.save).to be(true)
  end

  it "valid? clears prior errors before re-running" do
    klass = Class.new(item_class) { validates :name, presence: true }
    record = klass.new(name: "")
    record.valid?
    record.name = "ok"
    expect(record.valid?).to be(true)
    expect(record.errors[:name]).to be_empty
  end

  it "multiple violations on the same attribute accumulate" do
    klass = Class.new(item_class) do
      validates :name, presence: true, length: { in: 5..10 }
    end
    record = klass.new(name: "")
    record.valid?
    expect(record.errors[:name].length).to be >= 2
  end
end
