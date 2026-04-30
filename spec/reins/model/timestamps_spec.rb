require "spec_helper"

class TimestampedPost < Reins::Model::Base
  self.table_name = "posts"
end

RSpec.describe "Reins::Model timestamps" do
  around do |example|
    setup_test_db
    create_table(:posts,
                 "id INTEGER PRIMARY KEY, title TEXT, created_at TEXT, updated_at TEXT")
    example.run
  ensure
    teardown_test_db
  end

  it "created_at is set on first save and not changed on subsequent saves" do
    post = TimestampedPost.create!(title: "x")
    initial = post.created_at
    expect(initial).not_to be_nil

    sleep 0.01
    post.update(title: "y")
    expect(post.reload.created_at).to eq(initial)
  end

  it "updated_at is set on each save" do
    post = TimestampedPost.create!(title: "x")
    initial = post.updated_at
    expect(initial).not_to be_nil

    sleep 0.01
    post.update(title: "y")
    expect(post.reload.updated_at).not_to eq(initial)
  end
end
