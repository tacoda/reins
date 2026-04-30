require "spec_helper"
require "tmpdir"

RSpec.describe "Reins::Cli generate model" do
  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        Reins::Cli.start(%w[new myapp])
        Dir.chdir("myapp") { example.run }
      end
    end
  end

  it "writes app/models/post.rb inheriting ApplicationRecord" do
    Reins::Cli.start(%w[generate model Post title:string body:text])

    content = File.read("app/models/post.rb")
    expect(content).to include("class Post < ApplicationRecord")
  end

  it "writes a timestamped create_posts migration with the right columns" do
    Reins::Cli.start(%w[generate model Post title:string body:text])

    file = Dir["db/migrate/*_create_posts.rb"].first
    expect(file).to match(%r{db/migrate/\d{14}_create_posts\.rb\z})

    content = File.read(file)
    aggregate_failures do
      expect(content).to include("class CreatePosts < Reins::Migration")
      expect(content).to include("create_table :posts")
      expect(content).to include("t.string :title")
      expect(content).to include("t.text :body")
      expect(content).to include("t.timestamps")
    end
  end

  it "pluralizes correctly: Comment → comments, Category → categories" do
    Reins::Cli.start(%w[generate model Comment])
    comment_migration = Dir["db/migrate/*_create_comments.rb"].first
    expect(comment_migration).not_to be_nil
    expect(File.read(comment_migration)).to include("create_table :comments")

    Reins::Cli.start(%w[generate model Category])
    category_migration = Dir["db/migrate/*_create_categories.rb"].first
    expect(category_migration).not_to be_nil
    expect(File.read(category_migration)).to include("create_table :categories")
  end
end
