require "spec_helper"

class TxPost < Reins::Model::Base
  self.table_name = "posts"
end

RSpec.describe "Reins::Model transactions" do
  around do |example|
    setup_test_db
    create_table(:posts, "id INTEGER PRIMARY KEY, title TEXT")
    example.run
  ensure
    teardown_test_db
  end

  it "Model.transaction { ... } commits on success" do
    TxPost.transaction do
      TxPost.create!(title: "a")
      TxPost.create!(title: "b")
    end
    expect(TxPost.count).to eq(2)
  end

  it "Model.transaction { raise } rolls back; rows from inside the block are not persisted" do
    expect do
      TxPost.transaction do
        TxPost.create!(title: "a")
        raise "boom"
      end
    end.to raise_error(/boom/)

    expect(TxPost.count).to eq(0)
  end
end
