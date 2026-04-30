require "spec_helper"

RSpec.describe Reins::Env do
  around do |example|
    original = ENV.fetch("REINS_ENV", nil)
    example.run
  ensure
    ENV["REINS_ENV"] = original
  end

  it "Reins.env returns ENV['REINS_ENV'] (or 'development' when unset)" do
    ENV["REINS_ENV"] = "production"
    expect(Reins.env.to_s).to eq("production")

    ENV["REINS_ENV"] = nil
    expect(Reins.env.to_s).to eq("development")
  end

  it "responds to predicate methods for the standard envs" do
    ENV["REINS_ENV"] = "development"
    aggregate_failures do
      expect(Reins.env.development?).to be(true)
      expect(Reins.env.production?).to be(false)
      expect(Reins.env.test?).to be(false)
    end

    ENV["REINS_ENV"] = "production"
    expect(Reins.env.production?).to be(true)
  end

  it "compares string-equal to its environment name" do
    ENV["REINS_ENV"] = "development"
    expect(Reins.env).to eq("development")
    expect(Reins.env == "production").to be(false)
  end
end
