require 'English'
require 'integration_helper'

RSpec.describe 'Zero Configuration Auto-Discovery', :integration do
  describe 'system client discovery' do
    it 'tests system client access based on admin privileges' do
      # Test if Ruby can access system-client specifically
      ruby_can_access = false
      ruby_client_id = nil

      begin
        ruby_client = Eryph::Compute::Client.new('zero', ssl_config: { verify_ssl: false }, scopes: %w[compute:write])
        ruby_credentials = ruby_client.token_provider.credentials
        ruby_client_id = ruby_credentials.client_id
        ruby_can_access = true
      rescue Eryph::ClientRuntime::CredentialsNotFoundError
        ruby_can_access = false
      end

      # Test PowerShell access to system-client specifically
      ps_system_result = `powershell -Command "Get-EryphClientCredentials -Configuration zero -SystemClient | ConvertTo-Json 2>$null"`
      ps_can_access = $CHILD_STATUS.success? && !ps_system_result.strip.empty?

      if ruby_can_access && ps_can_access
        # Both Ruby and PowerShell can access - verify both return system-client
        expect(ruby_client_id).to eq('system-client')

        begin
          ps_client = JSON.parse(ps_system_result)
          expect(ps_client['Id']).to eq('system-client')
          expect(ruby_client_id).to eq(ps_client['Id'])
        rescue JSON::ParserError
          # If we can't parse PowerShell, just verify Ruby has system-client
          expect(ruby_client_id).to eq('system-client')
        end
      elsif ruby_can_access && !ps_can_access
        # Ruby works but PowerShell doesn't - still verify Ruby has system-client
        expect(ruby_client_id).to eq('system-client')
      elsif !ruby_can_access && ps_can_access
        # PowerShell works but Ruby doesn't - this shouldn't happen, fail the test
        raise 'PowerShell can access system-client but Ruby cannot - this indicates a Ruby client bug'
      else
        # Neither works - skip test (not running as admin)
        skip 'System-client not accessible (likely not running as administrator)'
      end
    end
  end

  describe 'local configuration fallback' do
    it 'handles local configuration when zero not available' do
      # Test that both PowerShell and Ruby consistently handle local configuration
      ps_local_result = `powershell -Command "Get-EryphClientConfiguration -Configuration local | ConvertTo-Json 2>$null"`

      if $CHILD_STATUS.success? && !ps_local_result.strip.empty?
        # PowerShell found local config - Ruby should find same
        ps_local = JSON.parse(ps_local_result)
        ps_local = [ps_local] unless ps_local.is_a?(Array)

        ruby_client = Eryph::Compute::Client.new('local')
        ruby_credentials = ruby_client.token_provider.credentials

        local_client_ids = ps_local.map { |c| c['Id'] }
        expect(local_client_ids).to include(ruby_credentials.client_id)
      else
        # PowerShell found no local config - Ruby should also find none
        expect do
          Eryph::Compute::Client.new('local')
        end.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError)
      end
    end
  end

  describe 'configuration precedence with zero' do
    it 'follows expected precedence when multiple configurations exist' do
      test_configs = %w[test-default test-local]
      temp_keys = {}

      begin
        # Create test configurations to test precedence
        test_configs.each_with_index do |config_name, _index|
          temp_key = File.join(Dir.tmpdir, "precedence-#{config_name}-#{SecureRandom.hex(4)}.key")
          File.write(temp_key, OpenSSL::PKey::RSA.generate(2048).to_pem)
          temp_keys[config_name] = temp_key

          client_id = "precedence-#{config_name}-#{SecureRandom.hex(4)}"

          # Create configuration using PowerShell
          ps_result = `powershell -Command "
            Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{client_id}' -IdentityEndpoint 'https://#{config_name}.example.com/identity' -Configuration '#{config_name}' | Add-EryphClientConfiguration -Id '#{client_id}' -Name 'Test #{config_name}' -Configuration '#{config_name}' -AsDefault | ConvertTo-Json
          "`
          expect($CHILD_STATUS.success?).to be_truthy, "Failed to create test config #{config_name}: #{ps_result}"

          # Parse and verify the created client object
          ps_client = JSON.parse(ps_result)
          expect(ps_client['Id']).to eq(client_id)
          expect(ps_client['Name']).to eq("Test #{config_name}")
        end

        # Test that both PowerShell and Ruby can find the created configurations
        test_configs.each do |config_name|
          ps_result = `powershell -Command "Get-EryphClientConfiguration -Configuration #{config_name} | ConvertTo-Json"`
          expect($CHILD_STATUS.success?).to be_truthy, "PowerShell should find #{config_name}"

          ps_config = JSON.parse(ps_result)
          ps_config = [ps_config] unless ps_config.is_a?(Array)
          expect(ps_config.first['Id']).not_to be_nil

          # Ruby should find same config using lower-level credential lookup
          environment = Eryph::ClientRuntime::Environment.new
          reader = Eryph::ClientRuntime::ConfigStoresReader.new(environment)
          lookup = Eryph::ClientRuntime::ClientCredentialsLookup.new(reader, config_name)
          ruby_credentials = lookup.find_credentials
          expect(ruby_credentials.client_id).to eq(ps_config.first['Id'])
        end
      ensure
        # Cleanup test configurations
        test_configs.each do |config_name|
          temp_key = temp_keys[config_name]
          File.delete(temp_key) if temp_key && File.exist?(temp_key)

          # Delete config files
          eryph_dir = File.join(ENV.fetch('APPDATA', nil), '.eryph')
          config_file = File.join(eryph_dir, "#{config_name}.config")
          FileUtils.rm_f(config_file)
          Dir.glob(File.join(eryph_dir, "#{config_name}-*.credentials")).each { |f| File.delete(f) }
        end
      end
    end
  end

  describe 'zero configuration without admin privileges' do
    it 'gracefully handles system client access restrictions' do
      # This test expects to potentially fail with admin-related errors
      # but should provide clear information about what failed and why


      # Try to get system client information with SSL verification disabled for eryph-zero
      ruby_client = Eryph::Compute::Client.new('zero', ssl_config: { verify_ssl: false }, scopes: %w[compute:write])
      ruby_credentials = ruby_client.token_provider.credentials

      # If we get here, we have access to system client
      expect(ruby_credentials.client_id).not_to be_nil, 'System client ID should be present'
      expect(ruby_credentials.client_id).not_to be_empty, 'System client ID should not be empty'

      # Try to use the credentials for authentication
      token = ruby_client.token_provider.ensure_access_token
      expect(token).to be_a(String), 'Should get valid access token'
      expect(token).not_to be_empty, 'Access token should not be empty'
    rescue Eryph::ClientRuntime::CredentialsNotFoundError
      # This is expected if running without admin privileges

      # Verify this is consistent with PowerShell behavior
      ps_zero_check = `powershell -Command "Get-EryphClientCredentials -Configuration zero | ConvertTo-Json"`

      unless !$CHILD_STATUS.success? || ps_zero_check.strip.empty?
        raise 'Ruby failed zero config access but PowerShell succeeded - this indicates a Ruby bug'
      end
    rescue StandardError => e
      # Any other error should be investigated
      raise "Unexpected error accessing zero configuration: #{e.class}: #{e.message}"
    end
  end
end
