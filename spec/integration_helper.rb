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

  # Final cleanup method to delete all test catlets
  def self.final_cleanup
    puts "\n=== Final Integration Test Cleanup ==="
    
    begin
      # Try different client configurations to find one that works
      client = nil
      
      %w[zero local default].each do |config|
        begin
          client = Eryph.compute_client(config, ssl_config: { verify_ssl: false }, scopes: %w[compute:write])
          break if client&.test_connection
        rescue StandardError
          client = nil
        end
      end
      
      unless client
        puts "Warning: No working client found for final cleanup"
        return
      end
      
      # Get all catlets and find test catlets
      catlets_response = client.catlets.catlets_list
      catlets_array = catlets_response.respond_to?(:value) ? catlets_response.value : catlets_response
      catlets_array = [catlets_array] unless catlets_array.is_a?(Array)

      test_catlets = catlets_array.select do |catlet|
        catlet.name&.start_with?('integration-test-')
      end

      if test_catlets.any?
        puts "Found #{test_catlets.length} test catlets to clean up:"
        test_catlets.each do |catlet|
          puts "  - #{catlet.name} (#{catlet.id})"
          begin
            delete_operation = client.catlets.catlets_delete(catlet.id)
            if delete_operation&.id
              puts "    Delete operation started: #{delete_operation.id} (fire-and-forget)"
            else
              puts "    Warning: Delete operation returned nil"
            end
          rescue StandardError => e
            puts "    Error: Delete failed: #{e.class}: #{e.message}"
          end
        end
        puts "All delete operations submitted - cleanup will continue in background"
      else
        puts "No test catlets found - cleanup complete"
      end
      
    rescue StandardError => e
      puts "Error during final cleanup: #{e.class}: #{e.message}"
      puts "Backtrace: #{e.backtrace.first(3).join('\n')}" if e.backtrace
    end
    
    puts "=== Final Cleanup Complete ===\n"
  end
end

RSpec.configure do |config|
  config.include IntegrationHelpers, :integration
  
  # Run final cleanup after all integration tests
  config.after(:suite) do
    # Only run cleanup if we're running integration tests
    if ENV['INTEGRATION_TESTS'] == '1'
      IntegrationHelpers.final_cleanup
    end
  end
end
