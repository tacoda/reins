require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Reins::Autoloader do
  around do |example|
    Dir.mktmpdir do |tmp|
      @tmp = tmp
      FileUtils.mkdir_p(File.join(tmp, "models"))
      example.run
    ensure
      described_class.reset!
    end
  end

  def write_file(path, body)
    full = File.join(@tmp, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, body)
    full
  end

  it "registers paths with Zeitwerk; a constant in a registered path resolves on first reference" do
    write_file("models/widget.rb", "class Widget; def self.greeting; 'hi'; end; end")
    described_class.setup([File.join(@tmp, "models")])

    expect(Widget.greeting).to eq("hi")
  ensure
    Object.send(:remove_const, :Widget) if Object.const_defined?(:Widget)
  end

  it "eager_load! requires every .rb file under registered paths" do
    write_file("models/eager_loaded.rb", "class EagerLoaded; end")
    described_class.setup([File.join(@tmp, "models")])
    described_class.eager_load!

    expect(Object.const_defined?(:EagerLoaded)).to be(true)
  ensure
    Object.send(:remove_const, :EagerLoaded) if Object.const_defined?(:EagerLoaded)
  end

  it "reload! invalidates the loader so a changed file's new content takes effect" do
    Reins.configure { |c| c.reload_classes = true }
    file = write_file("models/changeable.rb", "class Changeable; def self.value; :v1; end; end")

    described_class.setup([File.join(@tmp, "models")])

    expect(Changeable.value).to eq(:v1)

    File.write(file, "class Changeable; def self.value; :v2; end; end")
    described_class.reload!

    expect(Changeable.value).to eq(:v2)
  ensure
    Object.send(:remove_const, :Changeable) if Object.const_defined?(:Changeable)
    Reins.reset_config!
  end

  it "setup with no paths is a no-op; lookups behave under normal Ruby semantics" do
    described_class.setup([])
    expect { Object.const_get(:NoSuchConstantXyz) }.to raise_error(NameError)
  end
end
