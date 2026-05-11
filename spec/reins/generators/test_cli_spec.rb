require "spec_helper"
require "tmpdir"

RSpec.describe "Reins::Cli generate test" do
  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        Reins::Cli.start(%w[new myapp])
        Dir.chdir("myapp") { example.run }
      end
    end
  end

  it "scaffolds a test double and a use-case spec for an existing port" do
    Reins::Cli.start(%w[generate port PaymentGateway])
    Reins::Cli.start(%w[generate test PaymentGateway])

    aggregate_failures do
      expect(File.exist?("spec/doubles/payment_gateway_double.rb")).to be(true)
      expect(File.exist?("spec/use_cases/payment_gateway_use_case_spec.rb")).to be(true)
    end
  end

  it "without a NAME exits with a descriptive error" do
    expect { Reins::Cli.start(%w[generate test]) }
      .to raise_error(SystemExit)
      .or output(/NAME/).to_stderr
  end
end
