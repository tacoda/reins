require "spec_helper"

class Author < Reins::Model::Base; end

class AssocPost < Reins::Model::Base
  self.table_name = "posts"
  belongs_to :author
  has_many :comments, foreign_key: "post_id", class_name: "AssocComment"
  has_one :cover_image, foreign_key: "post_id", class_name: "AssocCoverImage"
end

class AssocComment < Reins::Model::Base
  self.table_name = "comments"
end

class AssocCoverImage < Reins::Model::Base
  self.table_name = "cover_images"
end

class TaggedItem < Reins::Model::Base
  self.table_name = "tagged_items"
  belongs_to :owner, class_name: "Author", foreign_key: "owner_id"
end

RSpec.describe "Reins::Model associations" do
  around do |example|
    setup_test_db
    create_table(:authors, "id INTEGER PRIMARY KEY, name TEXT")
    create_table(:posts, "id INTEGER PRIMARY KEY, title TEXT, author_id INTEGER")
    create_table(:comments, "id INTEGER PRIMARY KEY, post_id INTEGER, body TEXT")
    create_table(:cover_images, "id INTEGER PRIMARY KEY, post_id INTEGER, url TEXT")
    create_table(:tagged_items, "id INTEGER PRIMARY KEY, owner_id INTEGER")
    example.run
  ensure
    teardown_test_db
  end

  it "belongs_to defines a memoized accessor returning the parent record" do
    author = Author.create!(name: "Ada")
    post = AssocPost.create!(title: "p", author_id: author.id)

    first_call = post.author
    expect(first_call.name).to eq("Ada")
    expect(post.author).to be(first_call) # memoized — same instance
  end

  it "has_many returns a chainable Relation" do
    post = AssocPost.create!(title: "p")
    AssocComment.create!(post_id: post.id, body: "first")
    AssocComment.create!(post_id: post.id, body: "second")
    AssocComment.create!(post_id: 999,     body: "other-post")

    expect(post.comments).to be_a(Reins::Model::Relation)
    expect(post.comments.pluck(:body)).to contain_exactly("first", "second")
  end

  it "has_one returns the single child record (or nil)" do
    post = AssocPost.create!(title: "p")
    expect(post.cover_image).to be_nil

    AssocCoverImage.create!(post_id: post.id, url: "logo.png")
    expect(post.cover_image.url).to eq("logo.png")
  end

  it "class_name: and foreign_key: override the conventions" do
    author = Author.create!(name: "Ada")
    item = TaggedItem.create!(owner_id: author.id)
    expect(item.owner.name).to eq("Ada")
  end
end
