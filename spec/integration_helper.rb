require 'spec_helper'

# Integration tests are run based on directory selection
# Use: bundle exec rspec spec/unit for unit tests only
# Use: bundle exec rspec spec/integration for integration tests only

# Integration test configuration
RSpec.configure do |config|
  # Integration tests assume proper environment setup
  # No automatic skipping - let tests fail if environment not ready

  # Configure VCR to ignore localhost for integration tests
  config.around(:each, :integration) do |example|
    # Temporarily enable VCR localhost ignore
    original_vcr_ignore = ENV['VCR_IGNORE_LOCALHOST']
    ENV['VCR_IGNORE_LOCALHOST'] = '1'
    
    # Reconfigure VCR with localhost ignore
    VCR.configure do |c|
      c.ignore_hosts 'localhost', '127.0.0.1'
    end
    
    example.run
    ENV['VCR_IGNORE_LOCALHOST'] = original_vcr_ignore
    
    # Restore VCR configuration
    VCR.configure do |c|
      if original_vcr_ignore
        c.ignore_hosts 'localhost', '127.0.0.1'
      else
        c.unignore_hosts 'localhost', '127.0.0.1'
      end
    end
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
    default_options = { ssl_config: { verify_ssl: false } }
    Eryph.compute_client(test_config_name, **default_options, **options)
  end

  # Check if eryph instance is available
  def eryph_available?
    return false unless Eryph.credentials_available?(test_config_name)

    client = create_test_client
    client.test_connection
  rescue StandardError
    false
  end

  # Skip test if eryph is not available
  def skip_unless_eryph_available
    skip 'Eryph instance not available for testing' unless eryph_available?
  end
end

RSpec.configure do |config|
  config.include IntegrationHelpers, :integration
end
