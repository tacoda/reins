require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Reins::Adapters::Driven::Zeitwerk::Autoloader do
  let(:adapter) { described_class.new }

  around do |example|
    Dir.mktmpdir do |tmp|
      @tmp = tmp
      example.run
    ensure
      adapter.reset!
    end
  end

  def write_file(path, body)
    full = File.join(@tmp, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, body)
    full
  end

  it "includes the Autoloader port" do
    expect(described_class.include?(Reins::Ports::Driven::Autoloader)).to be(true)
  end

  it "responds to every method on the Autoloader port contract" do
    Reins::Ports::Driven::Autoloader::CONTRACT.each_key do |name|
      expect(adapter).to respond_to(name), "missing #{name} on Zeitwerk::Autoloader"
    end
  end

  it "#setup with no paths is a no-op" do
    adapter.setup([])
    expect { Object.const_get(:NoSuchConstantXyz) }.to raise_error(NameError)
  end

  it "#setup registers a path so constants in that path resolve" do
    write_file("models/zeitwerk_widget.rb", "class ZeitwerkWidget; def self.greeting; 'hi'; end; end")
    adapter.setup([File.join(@tmp, "models")])
    expect(ZeitwerkWidget.greeting).to eq("hi")
  ensure
    Object.send(:remove_const, :ZeitwerkWidget) if Object.const_defined?(:ZeitwerkWidget)
  end

  it "#eager_load! requires every file in registered paths" do
    write_file("models/zeitwerk_eager.rb", "class ZeitwerkEager; end")
    adapter.setup([File.join(@tmp, "models")])
    adapter.eager_load!
    expect(Object.const_defined?(:ZeitwerkEager)).to be(true)
  ensure
    Object.send(:remove_const, :ZeitwerkEager) if Object.const_defined?(:ZeitwerkEager)
  end
end
