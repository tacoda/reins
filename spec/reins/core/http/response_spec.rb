require "spec_helper"

RSpec.describe Reins::Core::Http::Response do
  it "exposes every field passed to the constructor" do
    response = described_class.new(
      status: 200,
      headers: { "Content-Type" => "text/html" },
      body: "ok"
    )
    expect(response.status).to eq(200)
    expect(response.headers).to eq("Content-Type" => "text/html")
    expect(response.body).to eq("ok")
  end

  it "defaults headers to {} and body to ''" do
    response = described_class.new(status: 204)
    expect(response.headers).to eq({})
    expect(response.body).to eq("")
  end

  it "compares equal when fields match" do
    a = described_class.new(status: 200, headers: { "X" => "1" }, body: "hi")
    b = described_class.new(status: 200, headers: { "X" => "1" }, body: "hi")
    expect(a).to eq(b)
  end

  it "compares unequal when any field differs" do
    a = described_class.new(status: 200, body: "hi")
    b = described_class.new(status: 404, body: "hi")
    expect(a).not_to eq(b)
  end

  it "does not expose a to_rack helper (translation lives in the adapter)" do
    response = described_class.new(status: 200)
    expect(response).not_to respond_to(:to_rack_tuple)
    expect(response).not_to respond_to(:to_a)
  end
end
