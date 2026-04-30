require "spec_helper"

RSpec.describe Reins::Configuration do
  before { Reins.reset_config! }
  after  { Reins.reset_config! }

  it "Reins.configure { |c| ... } mutates the singleton; settings persist across calls" do
    Reins.configure { |c| c.log_level = :error }
    Reins.configure { |c| c.eager_load = true }

    aggregate_failures do
      expect(Reins.config.log_level).to eq(:error)
      expect(Reins.config.eager_load).to be(true)
    end
  end

  it "default eager_load and log_level match the current Reins.env" do
    aggregate_failures do
      expect(Reins.config.eager_load).to be(false)
      expect(Reins.config.log_level).to eq(:warn)
    end
  end

  it "Reins.config.middleware returns a Reins::MiddlewareStack" do
    expect(Reins.config.middleware).to be_a(Reins::MiddlewareStack)
  end
end
