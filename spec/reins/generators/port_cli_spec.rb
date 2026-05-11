require "spec_helper"
require "tmpdir"

RSpec.describe "Reins::Cli generate port / adapter" do
  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        Reins::Cli.start(%w[new myapp])
        Dir.chdir("myapp") { example.run }
      end
    end
  end

  it "generate port PaymentGateway writes app/ports/payment_gateway.rb" do
    Reins::Cli.start(%w[generate port PaymentGateway])
    expect(File.exist?("app/ports/payment_gateway.rb")).to be(true)
    expect(File.read("app/ports/payment_gateway.rb")).to include("extend Reins::Port")
    expect(File.read("app/ports/payment_gateway.rb")).to include("direction :driven")
  end

  it "generate port InboundWebhook --driving sets direction :driving" do
    Reins::Cli.start(%w[generate port InboundWebhook --driving])
    expect(File.read("app/ports/inbound_webhook.rb")).to include("direction :driving")
  end

  it "generate port also writes a spec stub" do
    Reins::Cli.start(%w[generate port PaymentGateway])
    expect(File.exist?("spec/ports/payment_gateway_spec.rb")).to be(true)
  end

  it "generate adapter Stripe --port=PaymentGateway writes app/adapters/stripe.rb" do
    Reins::Cli.start(%w[generate port PaymentGateway])
    Reins::Cli.start(%w[generate adapter Stripe --port PaymentGateway])

    content = File.read("app/adapters/stripe.rb")
    expect(content).to include("class Stripe")
    expect(content).to include("include PaymentGateway")
  end

  it "generate adapter without --port exits with a descriptive error" do
    expect { Reins::Cli.start(%w[generate adapter Stripe]) }
      .to raise_error(SystemExit)
      .or output(/--port/).to_stderr
  end

  it "generate port --list prints every preset with descriptions" do
    expect { Reins::Cli.start(%w[generate port --list]) }
      .to output(/rack.*sqlite.*puma/m).to_stdout
  end
end
