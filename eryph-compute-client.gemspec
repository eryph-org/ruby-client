# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "eryph/version"

Gem::Specification.new do |s|
  s.name        = "eryph-compute-client"
  s.version     = Eryph::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Eryph Team"]
  s.email       = ["support@eryph.io"]
  s.homepage    = "https://github.com/eryph-org/ruby-computeclient"
  s.summary     = "Ruby client for Eryph Compute API"
  s.description = "Official Ruby client library for the Eryph Compute API with OAuth2 authentication support"
  s.license     = "MIT"
  s.required_ruby_version = ">= 2.7"
  
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/eryph-org/ruby-computeclient/issues",
    "changelog_uri" => "https://github.com/eryph-org/ruby-computeclient/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/eryph-org/ruby-computeclient",
    "homepage_uri" => "https://eryph.io",
    "documentation_uri" => "https://docs.eryph.io"
  }

  # Runtime dependencies
  s.add_runtime_dependency 'eryph-clientruntime', '~> 0.1'
  s.add_runtime_dependency 'faraday', '>= 1.0.1', '< 3.0'
  s.add_runtime_dependency 'faraday-multipart', '~> 1.0'
  s.add_runtime_dependency 'marcel', '~> 1.0'

  # Development dependencies
  s.add_development_dependency 'rspec', '~> 3.6', '>= 3.6.0'
  s.add_development_dependency 'webmock', '~> 3.0'
  s.add_development_dependency 'vcr', '~> 6.0'
  s.add_development_dependency 'rubocop', '~> 1.0'
  s.add_development_dependency 'yard', '~> 0.9'
  s.add_development_dependency 'simplecov', '~> 0.21'

  # Specify files to include
  s.files = Dir[
    'lib/**/*',
    'README.md',
    'CHANGELOG.md',
    'LICENSE',
    '*.gemspec'
  ].select { |f| File.file?(f) }
  
  s.test_files = Dir['spec/**/*_spec.rb']
  s.executables = []
  s.require_paths = ["lib"]
end