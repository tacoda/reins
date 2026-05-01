require "spec_helper"
require "reins/spec"

RSpec.describe "Reins::Spec metadata-driven contexts" do
  describe "type: :controller", type: :controller do
    it "includes Rack::Test::Methods (get, post, etc.)" do
      aggregate_failures do
        expect(self).to respond_to(:get)
        expect(self).to respond_to(:post)
      end
    end
  end

  describe "type: :integration", type: :integration do
    it "includes Rack::Test::Methods (get, post, etc.)" do
      aggregate_failures do
        expect(self).to respond_to(:get)
        expect(self).to respond_to(:post)
      end
    end
  end
end
