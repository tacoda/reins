require "spec_helper"
require "reins/spec/fixtures"

RSpec.describe Reins::Spec::Fixtures do
  around do |example|
    setup_test_db
    create_table(:posts, "id INTEGER PRIMARY KEY, title TEXT, body TEXT")
    @fixtures_dir = Dir.mktmpdir
    File.write(File.join(@fixtures_dir, "posts.yml"), <<~YAML)
      first:
        title: Hello
        body: World
      second:
        title: Other
        body: Stuff
    YAML
    example.run
  ensure
    FileUtils.rm_rf(@fixtures_dir) if @fixtures_dir
    teardown_test_db
  end

  let(:post_class) do
    Class.new(Reins::Model::Base) do
      self.table_name = "posts"
    end
  end

  it "creates one record per top-level YAML key" do
    described_class.load(post_class, File.join(@fixtures_dir, "posts.yml"))
    expect(post_class.count).to eq(2)
  end

  it "assigns the listed attributes to each record" do
    described_class.load(post_class, File.join(@fixtures_dir, "posts.yml"))
    titles = post_class.all.map(&:title).sort
    expect(titles).to eq(%w[Hello Other])
  end

  it "returns a hash keyed by fixture name" do
    fixtures = described_class.load(post_class, File.join(@fixtures_dir, "posts.yml"))
    aggregate_failures do
      expect(fixtures[:first].title).to eq("Hello")
      expect(fixtures[:second].body).to eq("Stuff")
    end
  end
end
