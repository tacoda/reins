require "spec_helper"
require "rack/mock"

RSpec.describe Reins::Adapters::Driving::Rack::App do
  describe "#call (passthrough mode)" do
    it "delegates to the wrapped Rack-compatible callable" do
      target = ->(_env) { [200, { "content-type" => "text/plain" }, ["hi"]] }
      adapter = described_class.new(target)
      env = Rack::MockRequest.env_for("/")

      expect(adapter.call(env)).to eq([200, { "content-type" => "text/plain" }, ["hi"]])
    end
  end

  describe ".translate_request" do
    it "produces a Reins::Core::Http::Request from a Rack env" do
      env = Rack::MockRequest.env_for("/posts/1?author=ada", method: "GET")
      request = described_class.translate_request(env)

      aggregate_failures do
        expect(request).to be_a(Reins::Core::Http::Request)
        expect(request.verb).to eq(:get)
        expect(request.path).to eq("/posts/1")
        expect(request.params).to include("author" => "ada")
        expect(request.env).to be(env)
      end
    end

    it "captures the Content-Type header from the env" do
      env = Rack::MockRequest.env_for("/", method: "POST",
                                           "CONTENT_TYPE" => "application/json")
      request = described_class.translate_request(env)
      expect(request.headers["Content-Type"]).to eq("application/json")
    end
  end

  describe ".translate_response" do
    it "produces a Rack tuple [status, headers, [body]]" do
      response = Reins::Core::Http::Response.new(
        status: 201,
        headers: { "content-type" => "text/html" },
        body: "created"
      )
      tuple = described_class.translate_response(response)

      expect(tuple).to eq([201, { "content-type" => "text/html" }, ["created"]])
    end

    it "wraps an array body as-is" do
      response = Reins::Core::Http::Response.new(
        status: 200,
        body: %w[chunk1 chunk2]
      )
      tuple = described_class.translate_response(response)
      expect(tuple[2]).to eq(%w[chunk1 chunk2])
    end
  end

  describe "round-trip" do
    it "preserves the meaningful fields through env → Request → Response → tuple" do
      env = Rack::MockRequest.env_for("/widgets?id=7", method: "GET")
      request = described_class.translate_request(env)
      response = Reins::Core::Http::Response.new(status: 200, headers: { "x-id" => request.params["id"] }, body: "ok")
      tuple = described_class.translate_response(response)

      expect(tuple).to eq([200, { "x-id" => "7" }, ["ok"]])
    end
  end
end
