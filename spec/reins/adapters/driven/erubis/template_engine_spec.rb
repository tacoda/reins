require "spec_helper"

RSpec.describe Reins::Adapters::Driven::Erubis::TemplateEngine do
  let(:engine) { described_class.new }

  it "includes the TemplateEngine port" do
    expect(described_class.include?(Reins::Ports::Driven::TemplateEngine)).to be(true)
  end

  it "responds to every method on the TemplateEngine port contract" do
    Reins::Ports::Driven::TemplateEngine::CONTRACT.each_key do |name|
      expect(engine).to respond_to(name), "missing #{name} on Erubis::TemplateEngine"
    end
  end

  describe "#compile" do
    it "returns a String of Ruby source that renders a plain template" do
      compiled = engine.compile("hello")
      expect(eval(compiled)).to eq("hello") # rubocop:disable Security/Eval
    end

    it "interpolates ERB expressions and HTML-escapes by default" do
      compiled = engine.compile('<%= "<x>" %>')
      expect(eval(compiled)).to eq("&lt;x&gt;") # rubocop:disable Security/Eval
    end

    it "<%== %> emits raw output without escaping" do
      compiled = engine.compile('<%== "<x>" %>')
      expect(eval(compiled)).to eq("<x>") # rubocop:disable Security/Eval
    end
  end
end
