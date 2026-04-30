require "spec_helper"

RSpec.describe Reins::Model::Errors do
  subject(:errors) { described_class.new }

  it "accumulates messages per attribute via add" do
    errors.add(:title, "can't be blank")
    errors.add(:title, "is too short")
    errors.add(:slug, "is invalid")

    expect(errors[:title]).to eq(["can't be blank", "is too short"])
    expect(errors[:slug]).to eq(["is invalid"])
  end

  it "humanizes the attribute name in full_messages" do
    errors.add(:author_name, "can't be blank")
    expect(errors.full_messages).to eq(["Author name can't be blank"])
  end

  it "clear empties all messages" do
    errors.add(:title, "x")
    errors.clear
    expect(errors).to be_empty
    expect(errors[:title]).to eq([])
  end
end
