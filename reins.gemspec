# frozen_string_literal: true

require_relative "lib/reins/version"

Gem::Specification.new do |spec|
  spec.name = "reins-web"
  spec.version = Reins::VERSION
  spec.authors = ["Ian Johnson"]
  spec.email = ["tacoda@hey.com"]

  spec.summary = "A Rack-based Web Framework"
  spec.description = "A Rack-based Web Framework, but with extra awesome."
  spec.homepage = "https://www.tacoda.dev/reins/"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tacoda/reins"
  spec.metadata["changelog_uri"] = "https://github.com/tacoda/reins"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # spec.files = Dir.chdir(__dir__) do
  #   `git ls-files -z`.split("\x0").reject do |f|
  #     (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
  #   end
  # end
  spec.files = Dir["{bin,lib}/**/*"] # + %w(LICENSE README.md)
  spec.bindir = "bin"
  spec.executables = [ 'reins' ]
  spec.require_paths = ["bin", "lib"]

  spec.add_dependency "rack"
  spec.add_dependency "erubis"
  spec.add_dependency "multi_json"
  spec.add_dependency "sqlite3"
  spec.add_dependency "thor"
  spec.add_dependency "puma"
  spec.add_dependency "rerun"
  spec.add_dependency "listen"

  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "minitest"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
