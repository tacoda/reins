require "spec_helper"

RSpec.describe Reins::View do
  describe "#evaluate" do
    it "renders a plain ERB template" do
      result = described_class.new.evaluate("Hello, world!")
      expect(result).to eq("Hello, world!")
    end

    it "interpolates ERB expressions" do
      result = described_class.new.evaluate("1 + 1 = <%= 1 + 1 %>")
      expect(result).to eq("1 + 1 = 2")
    end

    it "exposes instance variables set via set_vars to the template" do
      view = described_class.new
      view.set_vars("@name" => "Ada")
      expect(view.evaluate("Hi, <%= @name %>")).to eq("Hi, Ada")
    end
  end

  describe "#h" do
    it "escapes HTML special characters" do
      expect(described_class.new.h("<script>alert(1)</script>"))
        .to eq("&lt;script&gt;alert(1)&lt;/script&gt;")
    end

    it "escapes ampersands and quotes" do
      expect(described_class.new.h(%q(Tom & Jerry's "show")))
        .to eq("Tom &amp; Jerry&#39;s &quot;show&quot;")
    end

    it "leaves safe characters untouched" do
      expect(described_class.new.h("hello world")).to eq("hello world")
    end
  end
end
