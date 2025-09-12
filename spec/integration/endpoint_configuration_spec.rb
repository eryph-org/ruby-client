require 'English'
require 'integration_helper'
require 'securerandom'

RSpec.describe 'Endpoint Configuration Discovery', :integration do
  let(:test_config_name) { "test-endpoints-#{SecureRandom.hex(4)}" }
  let(:test_identity_endpoint) { 'https://custom-identity.example.com/identity' }
  let(:test_compute_endpoint) { 'https://custom-compute.example.com/compute' }

  after do
    # Cleanup test configurations by deleting files directly from %APPDATA%\Roaming\.eryph
    eryph_dir = File.join(ENV.fetch('APPDATA', nil), '.eryph')
    config_file = File.join(eryph_dir, "#{test_config_name}.config")
    FileUtils.rm_f(config_file)

    # Also clean credentials
    Dir.glob(File.join(eryph_dir, "#{test_config_name}-*.credentials")).each do |file|
      File.delete(file)
    end
  end

  describe 'endpoint URL discovery' do
    it 'Ruby discovers same endpoint URLs that PowerShell configured' do
      test_client_id = "test-endpoints-#{SecureRandom.hex(4)}"
      temp_key = File.join(Dir.tmpdir, "#{test_client_id}.key")
      File.write(temp_key, OpenSSL::PKey::RSA.generate(2048).to_pem)

      begin
        # PowerShell creates configuration with specific endpoints
        ps_create_result = `powershell -Command "
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{test_client_id}' -IdentityEndpoint '#{test_identity_endpoint}' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{test_client_id}' -Name 'Endpoint Test Client' -Configuration '#{test_config_name}' -AsDefault | ConvertTo-Json
        "`
        expect($CHILD_STATUS.success?).to be_truthy, "PowerShell failed to configure endpoints: #{ps_create_result}"

        # Parse and verify the created client object
        ps_client = JSON.parse(ps_create_result)
        expect(ps_client['Id']).to eq(test_client_id)
        expect(ps_client['Name']).to eq('Endpoint Test Client')

        # Verify PowerShell sees the endpoints
        ps_creds_result = `powershell -Command "Get-EryphClientCredentials -Configuration #{test_config_name} -Id '#{test_client_id}' | ConvertTo-Json"`
        expect($CHILD_STATUS.success?).to be_truthy, "PowerShell failed to retrieve credentials: #{ps_creds_result}"

        ps_creds = JSON.parse(ps_creds_result)
        expect(ps_creds['IdentityProvider']).to eq(test_identity_endpoint), "PowerShell has wrong identity endpoint: #{ps_creds['IdentityProvider']}"

        # Test Ruby discovers same endpoints using lower-level credential lookup
        environment = Eryph::ClientRuntime::Environment.new
        reader = Eryph::ClientRuntime::ConfigStoresReader.new(environment)
        lookup = Eryph::ClientRuntime::ClientCredentialsLookup.new(reader, test_config_name)
        ruby_credentials = lookup.find_credentials

        # Ruby should construct token endpoint from identity endpoint
        expected_token_endpoint = "#{test_identity_endpoint}/connect/token"
        expect(ruby_credentials.token_endpoint).to eq(expected_token_endpoint), "Ruby has wrong token endpoint: #{ruby_credentials.token_endpoint}"

        # NOTE: Compute endpoints are configured manually by users, not tested here
      ensure
        FileUtils.rm_f(temp_key)
      end
    end
  end

  describe 'endpoint separation' do
    it 'correctly handles identity endpoint configuration' do
      test_client_id = "test-separation-#{SecureRandom.hex(4)}"
      temp_key = File.join(Dir.tmpdir, "#{test_client_id}.key")
      File.write(temp_key, OpenSSL::PKey::RSA.generate(2048).to_pem)

      # Use specific identity endpoint
      different_identity = 'https://auth-server.example.com/identity'

      begin
        # Create configuration with specific identity endpoint
        ps_create_result = `powershell -Command "
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{test_client_id}' -IdentityEndpoint '#{different_identity}' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{test_client_id}' -Name 'Separated Endpoints Client' -Configuration '#{test_config_name}' -AsDefault | ConvertTo-Json
        "`
        expect($CHILD_STATUS.success?).to be_truthy, "PowerShell failed to configure identity endpoint: #{ps_create_result}"

        # Parse and verify the created client object
        ps_client = JSON.parse(ps_create_result)
        expect(ps_client['Id']).to eq(test_client_id)
        expect(ps_client['Name']).to eq('Separated Endpoints Client')

        # Test Ruby handles identity endpoint correctly using lower-level credential lookup
        environment = Eryph::ClientRuntime::Environment.new
        reader = Eryph::ClientRuntime::ConfigStoresReader.new(environment)
        lookup = Eryph::ClientRuntime::ClientCredentialsLookup.new(reader, test_config_name)
        ruby_credentials = lookup.find_credentials

        # Token endpoint should use the specified identity server
        expect(ruby_credentials.token_endpoint).to include('auth-server.example.com'), "Token endpoint should use identity server: #{ruby_credentials.token_endpoint}"
      ensure
        FileUtils.rm_f(temp_key)
      end
    end
  end
end
