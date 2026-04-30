require "spec_helper"

RSpec.describe Reins::View::Forms do
  let(:view) { Reins::View.new }

  describe "#form_with" do
    it "opens with the action and POST as the default method" do
      expect(view.form_with(url: "/posts")).to eq(%(<form action="/posts" method="post">))
    end

    it "honors an explicit method:" do
      expect(view.form_with(url: "/posts", method: :put))
        .to eq(%(<form action="/posts" method="put">))
    end
  end

  describe "field helpers" do
    it "text_field produces <input type=text> with the given name" do
      expect(view.text_field(:name)).to eq(%(<input type="text" name="name">))
    end

    it "text_field includes value: and other attributes" do
      expect(view.text_field(:name, value: "Ada", id: "user_name"))
        .to eq(%(<input type="text" name="name" value="Ada" id="user_name">))
    end

    it "text_area produces a <textarea> element with content" do
      expect(view.text_area(:bio, value: "x")).to eq(%(<textarea name="bio">x</textarea>))
    end

    it "submit produces <input type=submit value=...>" do
      expect(view.submit("Save")).to eq(%(<input type="submit" value="Save">))
    end

    it "hidden_field produces <input type=hidden name= value=>" do
      expect(view.hidden_field(:token, value: "abc"))
        .to eq(%(<input type="hidden" name="token" value="abc">))
    end

    it "label produces <label for=name>Humanized name</label>" do
      expect(view.label(:name)).to eq(%(<label for="name">Name</label>))
    end

    it "label uses the explicit text when given" do
      expect(view.label(:name, "Your name")).to eq(%(<label for="name">Your name</label>))
    end
  end
end
