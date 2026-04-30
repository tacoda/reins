require "spec_helper"
require "tmpdir"

RSpec.describe "Reins::Cli#new (app generator)" do
  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        example.run
      end
    end
  end

  before do
    Reins::Cli.start(%w[new myapp])
  end

  after do
    Object.send(:remove_const, :Myapp) if Object.const_defined?(:Myapp)
  end

  it "creates the standard project tree" do
    aggregate_failures do
      %w[
        myapp/config.ru
        myapp/Gemfile
        myapp/Rakefile
        myapp/.gitignore
        myapp/.rspec
        myapp/config/application.rb
        myapp/config/routes.rb
        myapp/config/database.yml
        myapp/bin/setup
        myapp/spec/spec_helper.rb
      ].each { |path| expect(File.exist?(path)).to be(true), "#{path} missing" }

      %w[
        myapp/app/controllers
        myapp/app/models
        myapp/app/views
        myapp/db/migrate
        myapp/public
      ].each { |path| expect(Dir.exist?(path)).to be(true), "#{path} missing" }
    end
  end

  it "config/application.rb defines Myapp::Application < Reins::Application" do
    content = File.read("myapp/config/application.rb")
    expect(content).to include("module Myapp")
    expect(content).to include("class Application < Reins::Application")
  end

  it "Gemfile pins reins-web and includes rspec in dev/test" do
    content = File.read("myapp/Gemfile")
    aggregate_failures do
      expect(content).to include("reins-web")
      expect(content).to match(/group\s+:development.*:test/m).or match(/group\s+:development,\s*:test/)
      expect(content).to include("rspec")
    end
  end

  it "generated app boots — Reins.application has routes after loading config" do
    Dir.chdir("myapp") do
      load "config/application.rb"
      app_class = Object.const_get("Myapp::Application")
      app = app_class.new
      load "config/routes.rb"
      expect(app.routes.rules).not_to be_empty
    end
  end

  it "writes meaningful environment files (not just placeholder comments)" do
    %w[development test production].each do |env|
      content = File.read("myapp/config/environments/#{env}.rb")
      expect(content).to include("Reins.configure"), "env file #{env}.rb has no Reins.configure call"
    end
  end

  it "writes the standard error pages under public/" do
    %w[404 422 500].each do |status|
      expect(File.exist?("myapp/public/#{status}.html")).to be(true), "missing public/#{status}.html"
    end
  end
end
