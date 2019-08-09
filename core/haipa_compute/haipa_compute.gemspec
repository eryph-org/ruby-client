# encoding: utf-8
# Copyright (c) dbosoft GmbH. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require '../haipa_compute/lib/module_definition'
require '../haipa_compute/lib/version'

Gem::Specification.new do |spec|
  spec.name          = 'haipa_compute'
  spec.version       = Haipa::Client::Compute::VERSION
  spec.authors       = 'Haipa Contributors'
  spec.email         = 'package-maintainers@haipa.io'
  spec.summary       = %q{Haipa Client Library for Ruby.}
  spec.description   = %q{Haipa Client Library for Ruby.}
  spec.homepage      = 'https://github.com/haipa/ruby-client'
  spec.license       = 'MIT'
  spec.metadata      = {
    'bug_tracker_uri' => 'https://github.com/haipa/haipa/issues',
    'documentation_uri' => 'https://github.com/haipa/ruby-client',
    'homepage_uri' => 'https://github.com/haipa/ruby-client',
    'source_code_uri' => "https://github.com/haipa/ruby-client"
  }

  spec.files         = Dir["LICENSE.txt", "lib/**/*"]
  spec.files.reject! { |fn| fn.include? "build.json" }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'dotenv', '~> 2'

  spec.add_runtime_dependency 'haipa_rest', '~> 0.11.2'
end
