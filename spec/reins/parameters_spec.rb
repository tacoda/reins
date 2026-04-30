require "spec_helper"

RSpec.describe Reins::Parameters do
  subject(:params) do
    described_class.new(
      "user" => { "name" => "Ada", "email" => "ada@example.com", "role" => "admin" },
      "extra" => "x"
    )
  end

  describe "#require" do
    it "returns the nested params when the key is present" do
      user = params.require(:user)
      expect(user).to be_a(described_class)
      expect(user[:name]).to eq("Ada")
    end

    it "raises Reins::ParameterMissing when the key is absent" do
      expect { params.require(:missing) }.to raise_error(Reins::ParameterMissing, /missing/)
    end
  end

  describe "#permit" do
    it "returns only the allowed keys; others are dropped silently" do
      filtered = params.require(:user).permit(:name, :email)
      expect(filtered.to_h).to eq("name" => "Ada", "email" => "ada@example.com")
      expect(filtered[:role]).to be_nil
    end
  end
end
