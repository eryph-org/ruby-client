# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "eryph/clientruntime/version"

Gem::Specification.new do |s|
  s.name        = "eryph-clientruntime"
  s.version     = Eryph::ClientRuntime::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Eryph Team"]
  s.email       = ["support@eryph.io"]
  s.homepage    = "https://github.com/eryph-org/ruby-client"
  s.summary     = "Eryph Client Runtime for Ruby"
  s.description = "Authentication, configuration, and credential lookup runtime for Eryph Ruby client libraries"
  s.license     = "MIT"
  s.required_ruby_version = ">= 2.7"
  
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/eryph-org/ruby-client/issues",
    "changelog_uri" => "https://github.com/eryph-org/ruby-client/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/eryph-org/ruby-client",
    "homepage_uri" => "https://eryph.io",
    "documentation_uri" => "https://www.eryph.io/docs"
  }

  # Runtime dependencies
  s.add_runtime_dependency 'jwt', '>= 2.0', '< 4.0'
  
  # Development dependencies moved to Gemfile for better version management

  # Specify files to include (only clientruntime files)
  s.files = Dir[
    'lib/eryph/clientruntime.rb',
    'lib/eryph/clientruntime/**/*',
    'README.md',
    'CHANGELOG.md',
    'LICENSE',
    '*.gemspec'
  ].select { |f| File.file?(f) }
  
  s.test_files = Dir['spec/eryph/clientruntime/**/*_spec.rb']
  s.executables = []
  s.require_paths = ["lib"]
end