$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'eryph/version'

Gem::Specification.new do |s|
  s.name        = 'eryph-compute'
  s.version     = Eryph::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Eryph Team']
  s.email       = ['support@eryph.io']
  s.homepage    = 'https://github.com/eryph-org/ruby-client'
  s.summary     = 'Ruby client for Eryph Compute API'
  s.description = 'Official Ruby client library for the Eryph Compute API with OAuth2 authentication support'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.7'

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/eryph-org/ruby-client/issues',
    'changelog_uri' => 'https://github.com/eryph-org/ruby-client/blob/main/packages/compute-client/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/eryph-org/ruby-client',
    'homepage_uri' => 'https://eryph.io',
    'documentation_uri' => 'https://www.eryph.io/docs',
    'rubygems_mfa_required' => 'true',
  }

  # Runtime dependencies
  s.add_dependency 'eryph-clientruntime', '~> 0.1'
  s.add_dependency 'faraday', '>= 1.0.1', '< 3.0'
  s.add_dependency 'faraday-multipart', '~> 1.0'
  s.add_dependency 'marcel', '~> 1.0'

  # Development dependencies moved to Gemfile for better version management

  # Specify files to include
  s.files = Dir[
    'lib/**/*',
    'README.md',
    'packages/compute-client/CHANGELOG.md',
    'LICENSE',
    '*.gemspec'
  ].select { |f| File.file?(f) }

  s.executables = []
  s.require_paths = ['lib']
end
