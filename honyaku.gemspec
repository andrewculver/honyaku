# frozen_string_literal: true

require_relative "lib/honyaku/version"

Gem::Specification.new do |spec|
  spec.name = "honyaku"
  spec.version = Honyaku::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]

  spec.summary = "Translate your Rails application using OpenAI"
  # spec.description = "Honyaku provides tools to streamline the process of translating and maintaining translations for your Rails application using OpenAI"
  spec.homepage = "https://github.com/andrewculver/honyaku"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "lib/**/*",
    "exe/*",
    "LICENSE.txt",
    "README.md"
  ]
  
  spec.bindir = "exe"
  spec.executables = ["honyaku"]
  spec.require_paths = ["lib"]

  # Add Thor as a dependency
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "ruby-openai", "~> 6.3"
  spec.add_dependency "yaml", "~> 0.3.0"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
