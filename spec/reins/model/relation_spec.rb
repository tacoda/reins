require "spec_helper"

class RelationPost < Reins::Model::Base
  self.table_name = "posts"
end

RSpec.describe "Reins::Model::Relation" do
  around do |example|
    setup_test_db
    create_table(:posts, "id INTEGER PRIMARY KEY, title TEXT, status TEXT, score INTEGER")
    example.run
  ensure
    teardown_test_db
  end

  before do
    RelationPost.create(title: "alpha",   status: "draft",     score: 1)
    RelationPost.create(title: "beta",    status: "published", score: 2)
    RelationPost.create(title: "gamma",   status: "published", score: 3)
  end

  it "Model.all returns a Relation enumerating every row" do
    rel = RelationPost.all
    expect(rel).to be_a(Reins::Model::Relation)
    expect(rel.map(&:title)).to contain_exactly("alpha", "beta", "gamma")
  end

  it "where(field: value) filters via parameterized SQL" do
    rel = RelationPost.where(status: "published")
    expect(rel.map(&:title)).to contain_exactly("beta", "gamma")
  end

  it "where with the string + bind form" do
    rel = RelationPost.where("score > ?", 1)
    expect(rel.map(&:title)).to contain_exactly("beta", "gamma")
  end

  it "order(:col) ascending and order(col: :desc) descending" do
    expect(RelationPost.order(:score).map(&:score)).to eq([1, 2, 3])
    expect(RelationPost.order(score: :desc).map(&:score)).to eq([3, 2, 1])
  end

  it "limit and offset constrain the result set" do
    titles = RelationPost.order(:score).limit(2).offset(1).map(&:title)
    expect(titles).to eq(%w[beta gamma])
  end

  it "count returns row count without loading records" do
    expect(RelationPost.where(status: "published").count).to eq(2)
  end

  it "pluck(:col) returns an Array of column values" do
    expect(RelationPost.order(:score).pluck(:title)).to eq(%w[alpha beta gamma])
  end

  it "find raises RecordNotFound; find_by returns nil; chains are lazy" do
    expect { RelationPost.find(99_999) }.to raise_error(Reins::Model::RecordNotFound)
    expect(RelationPost.find_by(title: "missing")).to be_nil

    rel = RelationPost.where(status: "published").order(:score).limit(1)
    expect(rel).to be_a(Reins::Model::Relation)
    expect(rel.first.title).to eq("beta")
  end
end
