require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/generated/'
  add_filter 'generated'
  
  add_group 'Client Runtime', 'lib/eryph/clientruntime'
  add_group 'Compute Client', 'lib/eryph/compute'
  
  minimum_coverage 80
end

require 'bundler/setup'
require 'eryph'
require 'rspec'
require 'webmock/rspec'
require 'vcr'
require 'factory_bot'
require 'faker'
require 'timecop'

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/.rspec_status"
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  
  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods
  
  # Clean up test files after each test
  config.after(:each) do
    FileUtils.rm_rf(Dir.glob('spec/tmp/*'))
    Timecop.return # Ensure time is reset after each test
  end
  
  # Ensure WebMock is enabled for unit tests but not integration tests
  config.before(:each) do |example|
    if example.metadata[:integration]
      WebMock.disable!
    else
      WebMock.enable!
    end
  end
  
  config.after(:each) do |example|
    WebMock.reset! unless example.metadata[:integration]
  end
end

# Configure Faker for consistent test data
Faker::Config.random = Random.new(42)