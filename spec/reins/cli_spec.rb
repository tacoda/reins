require "spec_helper"
require "reins/cli"
require "tmpdir"

RSpec.describe Reins::Cli do
  describe "#new" do
    it "scaffolds a project directory at the given name" do
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          described_class.start(%w[new myapp])
          expect(Dir.exist?("myapp")).to be(true)
          expect(Dir.exist?("myapp/app/controllers")).to be(true)
          expect(Dir.exist?("myapp/config")).to be(true)
        end
      end
    end

    it "copies the 500.html error page into the new project's public dir" do
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          described_class.start(%w[new myapp])
          expect(File.exist?("myapp/public/500.html")).to be(true)
        end
      end
    end

    it "does not create a stray 'testdir' directory" do
      Dir.mktmpdir do |tmp|
        Dir.chdir(tmp) do
          described_class.start(%w[new myapp])
          expect(Dir.exist?("testdir")).to be(false)
        end
      end
    end
  end
end
