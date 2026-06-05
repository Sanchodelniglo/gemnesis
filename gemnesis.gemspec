# frozen_string_literal: true

require_relative "lib/gemnesis/version"

Gem::Specification.new do |spec|
  spec.name          = "gemnesis"
  spec.version       = Gemnesis::VERSION
  spec.authors       = ["Romain Grossard"]
  spec.email         = ["rgrossadr@gmail.com"]

  spec.summary       = "Scaffold, build, and run Sega Mega Drive ROMs from Ruby (experimental)"
  spec.description   = "A Ruby CLI that wraps SGDK via Docker to scaffold, build, and run " \
                       "Sega Mega Drive / Genesis homebrew ROMs. Pre-alpha — API will change."
  spec.homepage      = "https://github.com/sanchodelniglo/gemnesis"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main"
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Dotfiles inside lib/gemnesis/templates/ (e.g. the template .gitignore) must
  # be packaged — `Dir["lib/**/*"]` alone skips them.
  lib_files = Dir.glob("lib/**/*", File::FNM_DOTMATCH).reject do |path|
    File.directory?(path) || [".", ".."].include?(File.basename(path))
  end
  spec.files = lib_files + Dir["exe/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.bindir        = "exe"
  spec.executables   = ["gemnesis"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.3"
end
