require "spec_helper"
require "tmpdir"

RSpec.describe "Reins::Cli generate use_case" do
  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        Reins::Cli.start(%w[new myapp])
        Dir.chdir("myapp") { example.run }
      end
    end
  end

  it "scaffolds the use case and spec with default deps" do
    Reins::Cli.start(%w[generate use_case CreatePost])

    aggregate_failures do
      expect(File.exist?("app/use_cases/create_post.rb")).to be(true)
      expect(File.exist?("spec/use_cases/create_post_spec.rb")).to be(true)

      content = File.read("app/use_cases/create_post.rb")
      expect(content).to match(/class CreatePost\b/)
      expect(content).to include("repository:")
      expect(content).to include("clock:")
    end
  end

  it "accepts custom deps as trailing positional args" do
    Reins::Cli.start(%w[generate use_case ChargePayment payment_gateway clock])

    content = File.read("app/use_cases/charge_payment.rb")
    expect(content).to include("payment_gateway:")
    expect(content).to include("clock:")
    expect(content).not_to include("repository:")
  end

  it "without a NAME exits with a descriptive error" do
    expect { Reins::Cli.start(%w[generate use_case]) }
      .to raise_error(SystemExit).or output(/NAME/).to_stderr
  end
end
