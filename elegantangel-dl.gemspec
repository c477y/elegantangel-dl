# frozen_string_literal: true

require_relative "lib/elegantangel_dl/version"

Gem::Specification.new do |spec|
  spec.name = "elegantangel_dl"
  spec.version = ElegantAngelDL::VERSION
  spec.authors = ["c477y"]
  spec.email = ["c477y@pm.me"]

  spec.summary = "Gem to download videos from ElegantAngel"
  spec.description = "Gem to download videos from ElegantAngel"
  spec.homepage = "https://www.github.com/c477y/elegantangel_dl"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize", "~> 0.8.1"
  spec.add_dependency "parallel", "~> 1.22"
  spec.add_dependency "ruby-progressbar", "~> 1.11"
  spec.add_dependency "thor", "~> 1.2"

  # HTTP gems
  spec.add_dependency "httparty", "~> 0.20.0"
  spec.add_dependency "nokogiri", "~> 1.13"

  # Selenium related gems and drivers
  # spec.add_dependency "selenium-devtools", "~> 0.101.0"
  spec.add_dependency "selenium-devtools", "~> 0.102.0"
  spec.add_dependency "selenium-webdriver", "~> 4.1"
  spec.add_dependency "webdrivers", "~> 5.0"

  spec.add_development_dependency "pry", "~> 0.14.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
