require "spec_helper"
require "tmpdir"
require "fileutils"

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

  describe "auto-escape" do
    it "<%= %> escapes HTML special characters by default" do
      result = described_class.new.evaluate('<%= "<x>" %>')
      expect(result).to eq("&lt;x&gt;")
    end

    it "<%== %> emits raw output without escaping" do
      result = described_class.new.evaluate('<%== "<x>" %>')
      expect(result).to eq("<x>")
    end
  end

  describe "layouts and partials" do
    around do |example|
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          FileUtils.mkdir_p("app/views/posts")
          FileUtils.mkdir_p("app/views/shared")
          FileUtils.mkdir_p("app/views/layouts")
          example.run
        end
      end
    end

    it "wraps the inner template in app/views/layouts/application.html.erb when present" do
      File.write("app/views/layouts/application.html.erb", "<wrap><%= yield %></wrap>")
      File.write("app/views/posts/show.html.erb", "inner")
      view = described_class.new
      expect(view.render_template("posts/show")).to eq("<wrap>inner</wrap>")
    end

    it "skips the layout when layout: false is passed" do
      File.write("app/views/layouts/application.html.erb", "<wrap><%= yield %></wrap>")
      File.write("app/views/posts/show.html.erb", "inner")
      view = described_class.new
      expect(view.render_template("posts/show", layout: false)).to eq("inner")
    end

    it "uses an explicit layout: 'name' to look up app/views/layouts/<name>.html.erb" do
      File.write("app/views/layouts/marketing.html.erb", "<m><%= yield %></m>")
      File.write("app/views/posts/show.html.erb", "inner")
      view = described_class.new
      expect(view.render_template("posts/show", layout: "marketing")).to eq("<m>inner</m>")
    end

    it "looks up partials with an underscore prefix: render \"shared/header\"" do
      File.write("app/views/shared/_header.html.erb", "HEADER")
      File.write("app/views/posts/show.html.erb", '<%= render "shared/header" %>')
      view = described_class.new
      expect(view.render_template("posts/show", layout: false)).to eq("HEADER")
    end

    it "passes locals to a partial via render \"shared/x\", locals: { ... }" do
      File.write("app/views/shared/_greeting.html.erb", "Hello, <%= name %>!")
      File.write("app/views/posts/show.html.erb",
                 '<%= render "shared/greeting", locals: { name: "Ada" } %>')
      view = described_class.new
      expect(view.render_template("posts/show", layout: false)).to eq("Hello, Ada!")
    end

    it "renders a partial once per item in collection, binding the partial name as a local" do
      File.write("app/views/shared/_post.html.erb", "[<%= post %>]")
      File.write(
        "app/views/posts/show.html.erb",
        '<%= render partial: "shared/post", collection: ["a", "b", "c"] %>'
      )
      view = described_class.new
      expect(view.render_template("posts/show", layout: false)).to eq("[a][b][c]")
    end

    it "content_for(:title) { 'X' } plus yield(:title) outputs 'X'" do
      File.write("app/views/layouts/application.html.erb",
                 "<title><%== yield :title %></title><body><%= yield %></body>")
      File.write("app/views/posts/show.html.erb",
                 "<% content_for(:title) { 'About' } %>inner-body")
      view = described_class.new
      expect(view.render_template("posts/show"))
        .to eq("<title>About</title><body>inner-body</body>")
    end

    it "bare yield inside a layout returns the inner template body" do
      File.write("app/views/layouts/application.html.erb", "[<%= yield %>]")
      File.write("app/views/posts/show.html.erb", "inner")
      view = described_class.new
      expect(view.render_template("posts/show")).to eq("[inner]")
    end
  end
end
