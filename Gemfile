source 'https://rubygems.org'

gemspec name: 'eryph-clientruntime'
gemspec name: 'eryph-compute'

group :development, :test do
  gem 'rake', '~> 13.0'
  gem 'rubocop', '~> 1.50' # Updated for Ruby 3.4 compatibility
  gem 'ruby-lsp', '~> 0.26', require: false # Ruby language server
  gem 'yard', '~> 0.9'
end

group :test do
  gem 'factory_bot', '~> 6.2'   # Test data factories
  gem 'faker', '~> 3.2'         # Generate fake test data
  gem 'rspec', '~> 3.12'
  gem 'simplecov', '~> 0.22'    # Code coverage reporting
  gem 'timecop', '~> 0.9'       # Time manipulation for testing
  gem 'vcr', '~> 6.1'           # For recording/replaying HTTP interactions
  gem 'webmock', '~> 3.18'      # For mocking HTTP requests in unit tests
end

gem 'kramdown', '~> 2.5'
