require "spec_helper"

RSpec.describe Reins::Adapters::Driven::Sqlite::Repository do
  before do
    setup_test_db
    create_table "posts", "id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR, body TEXT, author_id INTEGER"
    @repo = described_class.new(Reins::Database.connection)
  end

  after { teardown_test_db }

  it "includes the Repository port" do
    expect(described_class.include?(Reins::Ports::Driven::Repository)).to be(true)
  end

  it "responds to every method on the Repository port contract" do
    Reins::Ports::Driven::Repository::CONTRACT.each_key do |name|
      expect(@repo).to respond_to(name), "missing #{name} on Sqlite::Repository"
    end
  end

  it "#insert writes a row and returns last_insert_row_id" do
    id = @repo.insert("posts", { "title" => "Hi", "body" => "There" })
    expect(id).to eq(1)
    rows = Reins::Database.connection.execute("SELECT title FROM posts WHERE id = ?", [id])
    expect(rows.first["title"]).to eq("Hi")
  end

  it "#update only updates the named row" do
    a = @repo.insert("posts", { "title" => "A" })
    b = @repo.insert("posts", { "title" => "B" })
    @repo.update("posts", { "title" => "A!" }, "id", a)

    rows = Reins::Database.connection.execute("SELECT id, title FROM posts ORDER BY id")
    expect(rows.map { |r| r["title"] }).to eq(["A!", "B"])
    expect(rows.map { |r| r["id"] }).to eq([a, b])
  end

  it "#delete only removes the named row" do
    a = @repo.insert("posts", { "title" => "A" })
    b = @repo.insert("posts", { "title" => "B" })
    @repo.delete("posts", "id", a)

    rows = Reins::Database.connection.execute("SELECT id, title FROM posts")
    expect(rows.size).to eq(1)
    expect(rows.first["id"]).to eq(b)
  end

  it "#find_all applies wheres, orders, limit, offset" do
    @repo.insert("posts", { "title" => "A" })
    @repo.insert("posts", { "title" => "B" })
    @repo.insert("posts", { "title" => "C" })

    q = Reins::Core::Model::Query.new(table: "posts")
    q.add_where_fragment("title != ?", ["A"])
    q.add_order("title DESC")
    q.limit = 1
    q.offset = 0

    rows = @repo.find_all(q)
    expect(rows.map { |r| r["title"] }).to eq(["C"])
  end

  it "#count returns the row count after wheres" do
    @repo.insert("posts", { "title" => "A", "author_id" => 1 })
    @repo.insert("posts", { "title" => "B", "author_id" => 1 })
    @repo.insert("posts", { "title" => "C", "author_id" => 2 })

    q = Reins::Core::Model::Query.new(table: "posts")
    q.add_where_hash(author_id: 1)
    expect(@repo.count(q)).to eq(2)
  end

  it "#pluck returns values for a single column" do
    @repo.insert("posts", { "title" => "A" })
    @repo.insert("posts", { "title" => "B" })

    q = Reins::Core::Model::Query.new(table: "posts")
    q.add_order("title ASC")
    expect(@repo.pluck(q, "title")).to eq(%w[A B])
  end

  it "#transaction commits on normal return" do
    @repo.transaction do
      @repo.insert("posts", { "title" => "A" })
    end
    rows = Reins::Database.connection.execute("SELECT COUNT(*) AS c FROM posts")
    expect(rows.first["c"]).to eq(1)
  end

  it "#transaction rolls back on raise" do
    expect do
      @repo.transaction do
        @repo.insert("posts", { "title" => "A" })
        raise "nope"
      end
    end.to raise_error("nope")

    rows = Reins::Database.connection.execute("SELECT COUNT(*) AS c FROM posts")
    expect(rows.first["c"]).to eq(0)
  end
end
