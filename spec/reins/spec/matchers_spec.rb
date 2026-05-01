require "spec_helper"
require "reins/spec/matchers"

RSpec.describe Reins::Spec::Matchers do
  include described_class

  let(:ok_response) { Rack::Response.new("ok", 200) }
  let(:not_found_response) { Rack::Response.new("nf", 404) }
  let(:redirect_response) do
    Rack::Response.new("", 302).tap { |r| r.headers["Location"] = "/x" }
  end

  describe "have_http_status" do
    it "matches a Rack response with the given numeric status" do
      expect(ok_response).to have_http_status(200)
    end

    it "accepts symbolic status names" do
      expect(ok_response).to have_http_status(:ok)
    end

    it "fails with a useful message when the actual status differs" do
      matcher = have_http_status(:not_found)
      matcher.matches?(ok_response)
      expect(matcher.failure_message).to match(/expected.*404.*got.*200/)
    end
  end

  describe "redirect_to" do
    it "matches a 302 with the given Location header" do
      expect(redirect_response).to redirect_to("/x")
    end

    it "fails when the status isn't a 3xx redirect" do
      matcher = redirect_to("/x")
      matcher.matches?(ok_response)
      expect(matcher.failure_message).to match(/redirect|3\d\d/i)
    end
  end
end
