require "spec_helper"

RSpec.describe "Reins::Model::Base callbacks" do
  around do |example|
    setup_test_db
    create_table(:items, "id INTEGER PRIMARY KEY, name TEXT")
    example.run
  ensure
    teardown_test_db
  end

  let(:trace) { [] }

  def make_class(trace, &block)
    klass = Class.new(Reins::Model::Base) do
      self.table_name = "items"
    end
    klass.define_singleton_method(:trace) { trace }
    klass.class_eval(&block)
    klass
  end

  it "before_save runs before both INSERT and UPDATE" do
    t = trace
    klass = make_class(t) do
      before_save :note
      def note = self.class.trace << :before_save
    end

    record = klass.new(name: "x")
    record.save
    record.update(name: "y")

    expect(t.count(:before_save)).to eq(2)
  end

  it "before_validation runs before validators" do
    t = trace
    klass = make_class(t) do
      before_validation :prep
      validates :name, presence: true
      def prep = self.class.trace << :prep
    end

    klass.new(name: "x").valid?
    expect(t).to include(:prep)
  end

  it "after_create runs only on first save; after_update only on subsequent" do
    t = trace
    klass = make_class(t) do
      after_create :on_create
      after_update :on_update
      def on_create = self.class.trace << :create
      def on_update = self.class.trace << :update
    end

    record = klass.new(name: "x")
    record.save
    record.update(name: "y")

    expect(t).to eq(%i[create update])
  end

  it "callbacks declared on a parent class are inherited and run before the subclass's" do
    t = trace
    parent = make_class(t) do
      before_save :parent_hook
      def parent_hook = self.class.trace << :parent
    end
    child = Class.new(parent) do
      before_save :child_hook
      def child_hook = self.class.trace << :child
    end

    child.new(name: "x").save

    expect(t).to eq(%i[parent child])
  end
end
