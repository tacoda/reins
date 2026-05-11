require "spec_helper"

RSpec.describe Reins::Core::Http::Request do
  it "exposes every field passed to the constructor" do
    request = described_class.new(
      verb: :get,
      path: "/posts/1",
      params: { "id" => "1" },
      headers: { "Content-Type" => "text/html" },
      body: "hi",
      env: { "REQUEST_METHOD" => "GET" }
    )
    expect(request.verb).to eq(:get)
    expect(request.path).to eq("/posts/1")
    expect(request.params).to eq("id" => "1")
    expect(request.headers).to eq("Content-Type" => "text/html")
    expect(request.body).to eq("hi")
    expect(request.env).to eq("REQUEST_METHOD" => "GET")
  end

  it "defaults params, headers, body, and env to empty values" do
    request = described_class.new(verb: :get, path: "/")
    expect(request.params).to eq({})
    expect(request.headers).to eq({})
    expect(request.body).to eq("")
    expect(request.env).to eq({})
  end

  it "always normalizes verb to a lowercase Symbol" do
    expect(described_class.new(verb: "GET", path: "/").verb).to eq(:get)
    expect(described_class.new(verb: :POST, path: "/").verb).to eq(:post)
  end

  it "compares equal when fields match" do
    a = described_class.new(verb: :get, path: "/x", params: { "a" => "1" })
    b = described_class.new(verb: :get, path: "/x", params: { "a" => "1" })
    expect(a).to eq(b)
  end

  it "compares unequal when any field differs" do
    a = described_class.new(verb: :get, path: "/x")
    b = described_class.new(verb: :post, path: "/x")
    expect(a).not_to eq(b)
  end
end
