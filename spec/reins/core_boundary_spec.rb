require "spec_helper"

CORE_GLOB = File.expand_path("../../lib/reins/core/**/*.rb", __dir__).freeze

FORBIDDEN_REQUIRES = %w[
  rack
  sqlite3
  erubis
  puma
  thor
  fileutils
  zeitwerk
].freeze

FORBIDDEN_CONSTANT_PATTERNS = {
  "Rack" => /\bRack(::|\.|\b)/,
  "SQLite3" => /\bSQLite3(::|\.|\b)/,
  "Erubis" => /\bErubis(::|\.|\b)/,
  "Puma" => /\bPuma(::|\.|\b)/,
  "Thor" => /\bThor(::|\.|\b)/,
  "Zeitwerk" => /\bZeitwerk(::|\.|\b)/
}.freeze

# The core is pure. It must not require, reference, or otherwise depend on
# infrastructure libraries — those live behind driven adapters.
RSpec.describe "core purity boundary" do
  def core_files
    Dir[CORE_GLOB]
  end

  def each_core_line
    core_files.each do |file|
      File.readlines(file, encoding: "UTF-8").each_with_index do |line, idx|
        next if line.strip.empty?
        next if line.strip.start_with?("#")

        yield file, idx + 1, line
      end
    end
  end

  FORBIDDEN_REQUIRES.each do |gem_name|
    it "no core file requires #{gem_name.inspect}" do
      offenders = []
      each_core_line do |file, line_no, line|
        next unless line =~ /^\s*require\s+["']#{Regexp.escape(gem_name)}["']/

        offenders << "#{file}:#{line_no} #{line.strip}"
      end
      expect(offenders).to eq([]), "core must not require #{gem_name}:\n#{offenders.join("\n")}"
    end
  end

  FORBIDDEN_CONSTANT_PATTERNS.each do |constant, pattern|
    it "no core file references #{constant}" do
      offenders = []
      each_core_line do |file, line_no, line|
        # strip string literals & comments so legitimate prose doesn't trip the check
        scrubbed = line.gsub(/#.*$/, "").gsub(/(["']).*?\1/, "")
        next unless scrubbed =~ pattern

        offenders << "#{file}:#{line_no} #{line.strip}"
      end
      expect(offenders).to eq([]), "core must not reference #{constant}:\n#{offenders.join("\n")}"
    end
  end
end
