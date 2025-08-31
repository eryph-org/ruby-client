require 'spec_helper'

# Integration tests are run based on directory selection
# Use: bundle exec rspec spec/unit for unit tests only
# Use: bundle exec rspec spec/integration for integration tests only

# Integration test configuration
RSpec.configure do |config|
  # Integration tests assume proper environment setup
  # No automatic skipping - let tests fail if environment not ready
  
  # Set default test configuration name
  config.around(:each, :integration) do |example|
    original_env = ENV['ERYPH_TEST_CONFIG']
    ENV['ERYPH_TEST_CONFIG'] ||= 'test'
    
    example.run
    
    ENV['ERYPH_TEST_CONFIG'] = original_env
  end
end

# Helper methods for integration tests
module IntegrationHelpers
  # Get the test configuration name
  def test_config_name
    ENV['ERYPH_TEST_CONFIG'] || 'test'
  end
  
  # Create a test client
  def create_test_client(**options)
    default_options = { verify_ssl: false }
    Eryph.compute_client(test_config_name, **default_options.merge(options))
  end
  
  # Check if eryph instance is available
  def eryph_available?
    return false unless Eryph.credentials_available?(test_config_name)
    
    client = create_test_client
    client.test_connection
  rescue
    false
  end
  
  # Skip test if eryph is not available
  def skip_unless_eryph_available
    skip "Eryph instance not available for testing" unless eryph_available?
  end
end

RSpec.configure do |config|
  config.include IntegrationHelpers, :integration
end