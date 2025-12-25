# frozen_string_literal: true

require_relative "lib/zenrows/version"

Gem::Specification.new do |spec|
  spec.name = "zenrows"
  spec.version = Zenrows::VERSION
  spec.authors = ["Ernest Bursa"]
  spec.email = ["ernest.bursa@fourthwall.com"]

  spec.summary = "Ruby client for ZenRows web scraping API via proxy mode"
  spec.description = "A Ruby gem for ZenRows web scraping proxy with multi-backend support (http.rb primary), " \
                     "JavaScript rendering, premium proxies, and comprehensive browser automation via JS instructions."
  spec.homepage = "https://github.com/swistaczek/zenrows-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/swistaczek/zenrows-rb"
  spec.metadata["changelog_uri"] = "https://github.com/swistaczek/zenrows-rb/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/zenrows"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "http", "~> 5.0"
  spec.add_dependency "addressable", "~> 2.8"
end
