require "spec_helper"

class PersistencePost < Reins::Model::Base
  self.table_name = "posts"
end

class PersistencePostWithValidation < Reins::Model::Base
  self.table_name = "posts"
  validates :title, presence: true
end

RSpec.describe "Reins::Model::Base persistence" do
  around do |example|
    setup_test_db
    create_table(:posts, "id INTEGER PRIMARY KEY, title TEXT, body TEXT")
    example.run
  ensure
    teardown_test_db
  end

  it "Model.new(attrs) builds an unpersisted record" do
    post = PersistencePost.new(title: "x")
    expect(post.new_record?).to be(true)
    expect(post.persisted?).to be(false)
  end

  it "save inserts the row, assigns id, flips persisted state" do
    post = PersistencePost.new(title: "x")
    expect(post.save).to be(true)
    expect(post.id).to be_a(Integer)
    expect(post.persisted?).to be(true)
    expect(PersistencePost.count).to eq(1)
  end

  it "save returns false and skips insert when validation fails" do
    post = PersistencePostWithValidation.new(title: nil)
    expect(post.save).to be(false)
    expect(PersistencePostWithValidation.count).to eq(0)
  end

  it "save! raises Reins::Model::RecordInvalid on validation failure" do
    post = PersistencePostWithValidation.new(title: nil)
    expect { post.save! }.to raise_error(Reins::Model::RecordInvalid)
  end

  it "update(attrs) saves the new values" do
    post = PersistencePost.new(title: "x")
    post.save
    post.update(title: "y")
    expect(PersistencePost.find(post.id).title).to eq("y")
  end

  it "destroy removes the row" do
    post = PersistencePost.new(title: "x")
    post.save
    post.destroy
    expect(PersistencePost.count).to eq(0)
  end

  it "create returns the (possibly invalid) record; create! raises on invalid" do
    valid_record = PersistencePostWithValidation.create(title: "x")
    expect(valid_record).to be_persisted

    invalid_record = PersistencePostWithValidation.create(title: nil)
    expect(invalid_record).not_to be_persisted
    expect(invalid_record.errors[:title]).not_to be_empty

    expect { PersistencePostWithValidation.create!(title: nil) }
      .to raise_error(Reins::Model::RecordInvalid)
  end

  it "SQL is fully parameterized — values with quotes/sql metachars round-trip intact" do
    nasty = "Robert'); DROP TABLE posts;--"
    post = PersistencePost.new(title: nasty)
    post.save
    expect(PersistencePost.find(post.id).title).to eq(nasty)
    expect(PersistencePost.count).to eq(1)
  end
end
