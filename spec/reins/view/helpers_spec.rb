require "spec_helper"

RSpec.describe Reins::View::Helpers do
  let(:view) { Reins::View.new }

  describe "#link_to" do
    it "produces an anchor tag with href and inner text" do
      expect(view.link_to("text", "/x")).to eq(%(<a href="/x">text</a>))
    end

    it "accepts arbitrary html attributes as keyword args" do
      expect(view.link_to("text", "/x", class: "btn"))
        .to eq(%(<a href="/x" class="btn">text</a>))
    end
  end

  describe "#tag" do
    it "wraps content in the given element with attributes" do
      expect(view.tag(:div, "content", class: "x")).to eq(%(<div class="x">content</div>))
    end

    it "renders void elements (br, img, link, etc.) as self-closing-style" do
      expect(view.tag(:br)).to eq("<br>")
    end
  end

  describe "#image_tag" do
    it "produces an img tag pointing under /" do
      expect(view.image_tag("logo.png")).to eq(%(<img src="/logo.png">))
    end

    it "accepts arbitrary attributes" do
      expect(view.image_tag("logo.png", alt: "L")).to eq(%(<img src="/logo.png" alt="L">))
    end
  end

  describe "#url_for" do
    it "returns a string path unchanged when no params are given" do
      expect(view.url_for("/posts")).to eq("/posts")
    end

    it "appends query parameters when keyword args are given" do
      expect(view.url_for("/posts", page: 2, sort: "name")).to eq("/posts?page=2&sort=name")
    end
  end

  describe "asset helpers" do
    it "stylesheet_link_tag points at /css/<name>.css" do
      expect(view.stylesheet_link_tag("app"))
        .to eq(%(<link rel="stylesheet" href="/css/app.css">))
    end

    it "javascript_include_tag points at /js/<name>.js" do
      expect(view.javascript_include_tag("app")).to eq(%(<script src="/js/app.js"></script>))
    end
  end
end
