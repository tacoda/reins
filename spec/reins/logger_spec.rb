require "spec_helper"
require "tmpdir"

RSpec.describe "Reins.logger" do
  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        Reins.reset_logger!
        example.run
      ensure
        Reins.reset_logger!
        Reins.reset_config!
      end
    end
  end

  it "writes to log/<env>.log at the configured level" do
    Reins.configure { |c| c.log_level = :debug }
    Reins.logger.debug("hello")

    expect(File.exist?("log/test.log")).to be(true)
    expect(File.read("log/test.log")).to include("hello")
  end

  it "auto-creates the log directory if missing" do
    expect(Dir.exist?("log")).to be(false)
    Reins.logger.info("creates dir")
    expect(Dir.exist?("log")).to be(true)
  end
end
