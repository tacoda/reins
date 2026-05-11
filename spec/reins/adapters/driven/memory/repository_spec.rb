require "spec_helper"

RSpec.describe Reins::Adapters::Driven::Memory::Repository do
  let(:repo) { described_class.new }

  it "includes the Repository port" do
    expect(described_class.include?(Reins::Ports::Driven::Repository)).to be(true)
  end

  it "responds to every method on the Repository port contract" do
    Reins::Ports::Driven::Repository::CONTRACT.each_key do |name|
      expect(repo).to respond_to(name), "missing #{name} on Memory::Repository"
    end
  end

  it "round-trips writes through #insert + #find_all" do
    a = repo.insert("posts", { "title" => "A" })
    b = repo.insert("posts", { "title" => "B" })

    q = Reins::Core::Model::Query.new(table: "posts")
    rows = repo.find_all(q)

    expect(rows).to eq([
                         { "id" => a, "title" => "A" },
                         { "id" => b, "title" => "B" }
                       ])
  end

  it "#update only modifies the named row" do
    a = repo.insert("posts", { "title" => "A" })
    repo.insert("posts", { "title" => "B" })

    repo.update("posts", { "title" => "A!" }, "id", a)

    q = Reins::Core::Model::Query.new(table: "posts")
    titles = repo.find_all(q).map { |r| r["title"] }
    expect(titles).to eq(["A!", "B"])
  end

  it "#delete only removes the named row" do
    a = repo.insert("posts", { "title" => "A" })
    b = repo.insert("posts", { "title" => "B" })

    repo.delete("posts", "id", a)

    q = Reins::Core::Model::Query.new(table: "posts")
    expect(repo.find_all(q).map { |r| r["id"] }).to eq([b])
  end

  it "filters by Hash where" do
    repo.insert("posts", { "title" => "A", "author_id" => 1 })
    repo.insert("posts", { "title" => "B", "author_id" => 2 })

    q = Reins::Core::Model::Query.new(table: "posts")
    q.add_where_hash(author_id: 1)
    expect(repo.find_all(q).map { |r| r["title"] }).to eq(["A"])
  end

  it "supports '<col> = ?' and '<col> != ?' string fragments" do
    repo.insert("posts", { "title" => "A" })
    repo.insert("posts", { "title" => "B" })
    repo.insert("posts", { "title" => "C" })

    q = Reins::Core::Model::Query.new(table: "posts")
    q.add_where_fragment("title != ?", ["A"])
    expect(repo.find_all(q).map { |r| r["title"] }).to eq(%w[B C])

    q2 = Reins::Core::Model::Query.new(table: "posts")
    q2.add_where_fragment("title = ?", ["B"])
    expect(repo.find_all(q2).map { |r| r["title"] }).to eq(["B"])
  end

  it "raises a descriptive error on unsupported string fragments" do
    repo.insert("posts", { "title" => "A" })
    q = Reins::Core::Model::Query.new(table: "posts")
    q.add_where_fragment("title LIKE ?", ["%A%"])
    expect { repo.find_all(q) }
      .to raise_error(/not supported.*LIKE|Memory::Repository/i)
  end

  it "applies order, limit, and offset" do
    repo.insert("posts", { "title" => "A" })
    repo.insert("posts", { "title" => "B" })
    repo.insert("posts", { "title" => "C" })

    q = Reins::Core::Model::Query.new(table: "posts")
    q.add_order("title DESC")
    q.limit = 2
    q.offset = 1

    expect(repo.find_all(q).map { |r| r["title"] }).to eq(%w[B A])
  end

  it "#count and #pluck respect wheres" do
    repo.insert("posts", { "title" => "A", "author_id" => 1 })
    repo.insert("posts", { "title" => "B", "author_id" => 1 })
    repo.insert("posts", { "title" => "C", "author_id" => 2 })

    q = Reins::Core::Model::Query.new(table: "posts")
    q.add_where_hash(author_id: 1)
    expect(repo.count(q)).to eq(2)
    expect(repo.pluck(q, "title")).to eq(%w[A B])
  end

  it "#transaction rolls back on raise" do
    repo.insert("posts", { "title" => "A" })

    expect do
      repo.transaction do
        repo.insert("posts", { "title" => "B" })
        raise "nope"
      end
    end.to raise_error("nope")

    q = Reins::Core::Model::Query.new(table: "posts")
    expect(repo.find_all(q).map { |r| r["title"] }).to eq(["A"])
  end

  it "#transaction commits on normal return" do
    repo.transaction do
      repo.insert("posts", { "title" => "A" })
      repo.insert("posts", { "title" => "B" })
    end
    q = Reins::Core::Model::Query.new(table: "posts")
    expect(repo.find_all(q).size).to eq(2)
  end
end
