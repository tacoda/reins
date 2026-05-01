require "spec_helper"
require "reins/spec/model"
require "reins/spec/fixtures"

RSpec.describe Reins::Spec::Model do
  around do |example|
    setup_test_db
    create_table(:widgets, "id INTEGER PRIMARY KEY, name TEXT")
    example.run
  ensure
    teardown_test_db
  end

  let(:widget_class) do
    Class.new(Reins::Model::Base) do
      self.table_name = "widgets"
    end
  end

  it "records created inside in_transaction roll back at the end" do
    described_class.in_transaction do
      widget_class.create!(name: "x")
      expect(widget_class.count).to eq(1)
    end
    expect(widget_class.count).to eq(0)
  end

  it "fixture data loaded inside in_transaction is also rolled back" do
    fixtures_dir = Dir.mktmpdir
    File.write(File.join(fixtures_dir, "widgets.yml"), <<~YAML)
      first:
        name: from-fixture
    YAML

    described_class.in_transaction do
      Reins::Spec::Fixtures.load(widget_class, File.join(fixtures_dir, "widgets.yml"))
      expect(widget_class.count).to eq(1)
    end

    expect(widget_class.count).to eq(0)
  ensure
    FileUtils.rm_rf(fixtures_dir) if fixtures_dir
  end

  it "two consecutive in_transaction blocks each see a clean slate" do
    described_class.in_transaction { widget_class.create!(name: "first-call") }
    described_class.in_transaction do
      expect(widget_class.count).to eq(0)
      widget_class.create!(name: "second-call")
    end
    expect(widget_class.count).to eq(0)
  end
end
