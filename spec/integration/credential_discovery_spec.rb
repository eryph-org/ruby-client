require 'integration_helper'
require 'securerandom'

RSpec.describe 'Credential Discovery', :integration do
  let(:test_config_name) { "test-creds-#{SecureRandom.hex(4)}" }
  
  after do
    # Cleanup test configurations by deleting files directly from %APPDATA%\Roaming\.eryph
    eryph_dir = File.join(ENV['APPDATA'], '.eryph')
    config_file = File.join(eryph_dir, "#{test_config_name}.config")
    File.delete(config_file) if File.exist?(config_file)
    
    # Also clean credentials
    Dir.glob(File.join(eryph_dir, "#{test_config_name}-*.credentials")).each do |file|
      File.delete(file)
    end
    
    # Clean from current directory too
    current_eryph_dir = "./.eryph"
    if Dir.exist?(current_eryph_dir)
      config_file = File.join(current_eryph_dir, "#{test_config_name}.config")
      File.delete(config_file) if File.exist?(config_file)
      Dir.glob(File.join(current_eryph_dir, "#{test_config_name}-*.credentials")).each do |file|
        File.delete(file)
      end
    end
  end
  
  describe 'private key discovery' do
    it 'Ruby discovers same private key that PowerShell configured' do
      test_client_id = "cred-test-#{SecureRandom.hex(4)}"
      temp_key = File.join(Dir.tmpdir, "#{test_client_id}.key")
      
      # Generate specific RSA key for testing
      test_private_key = OpenSSL::PKey::RSA.generate(2048)
      File.write(temp_key, test_private_key.to_pem)
      
      begin
        # PowerShell creates client with specific private key using pipe pattern
        ps_cred_result = `powershell -Command "
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{test_client_id}' -IdentityEndpoint 'https://cred-test.example.com/identity' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{test_client_id}' -Name 'Credential Test Client' -Configuration '#{test_config_name}' | ConvertTo-Json
        "`
        expect($?.success?).to be_truthy, "PowerShell failed to create credentials: #{ps_cred_result}"
        
        # Parse and verify the created client object
        ps_client = JSON.parse(ps_cred_result)
        expect(ps_client['Id']).to eq(test_client_id)
        expect(ps_client['Name']).to eq('Credential Test Client')
        
        # Verify PowerShell can retrieve the credentials
        ps_get_creds = `powershell -Command "Get-EryphClientCredentials -Configuration #{test_config_name} -Id #{test_client_id} | ConvertTo-Json"`
        expect($?.success?).to be_truthy, "PowerShell failed to retrieve stored credentials"
        
        ps_creds = JSON.parse(ps_get_creds)
        expect(ps_creds['Id']).to eq(test_client_id), "PowerShell retrieved wrong credentials: #{ps_creds['Id']}"
        
        # Test Ruby discovers same credentials
        ruby_client = Eryph::Compute::Client.new(test_config_name)
        ruby_credentials = ruby_client.token_provider.credentials
        
        expect(ruby_credentials.client_id).to eq(test_client_id), "Ruby found wrong client ID: #{ruby_credentials.client_id}"
        
        # Verify Ruby can use the private key for JWT creation
        jwt_assertion = ruby_client.token_provider.send(:create_client_assertion)
        expect(jwt_assertion).to be_a(String), "Ruby failed to create JWT assertion"
        expect(jwt_assertion.split('.').length).to eq(3), "Invalid JWT format: #{jwt_assertion}"
        
        # Verify JWT can be decoded with the original public key
        decoded_jwt = JWT.decode(jwt_assertion, test_private_key.public_key, true, algorithm: 'RS256')
        decoded_claims = decoded_jwt[0]
        
        expect(decoded_claims['iss']).to eq(test_client_id), "JWT issuer mismatch: #{decoded_claims['iss']}"
        expect(decoded_claims['sub']).to eq(test_client_id), "JWT subject mismatch: #{decoded_claims['sub']}"
        
        
      ensure
        File.delete(temp_key) if File.exist?(temp_key)
      end
    end
  end
  
  describe 'credential store separation' do
    it 'handles credentials in different store than client configuration' do
      test_client_id = "store-sep-#{SecureRandom.hex(4)}"
      temp_key = File.join(Dir.tmpdir, "#{test_client_id}.key")
      File.write(temp_key, OpenSSL::PKey::RSA.generate(2048).to_pem)
      
      begin
        # PowerShell can configure client and credentials to use different stores
        current_dir = Dir.pwd
        ps_sep_result = `powershell -Command "
          cd '#{current_dir}';
          Set-EryphConfigurationStore -All CurrentDirectory;
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{test_client_id}' -IdentityEndpoint 'https://separated.example.com/identity' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration | ConvertTo-Json
        "`
        expect($?.success?).to be_truthy, "PowerShell failed separated store setup: #{ps_sep_result}"
        
        # Parse and verify the created client object
        ps_client = JSON.parse(ps_sep_result)
        expect(ps_client['Id']).to eq(test_client_id)
        
        ps_verify_creds = `powershell -Command "
          cd '#{current_dir}';
          Set-EryphConfigurationStore -All CurrentDirectory;
          Get-EryphClientCredentials -Configuration #{test_config_name} -Id #{test_client_id} | ConvertTo-Json
        "`
        expect($?.success?).to be_truthy, "PowerShell failed to verify separated credentials, Response: #{ps_verify_creds}"
        
        ps_creds = JSON.parse(ps_verify_creds)
        expect(ps_creds['Id']).to eq(test_client_id), "PowerShell credential verification failed, Response: #{ps_verify_creds}"

        # Test Ruby can handle separated stores
        ruby_client = Eryph::Compute::Client.new(test_config_name)
        ruby_credentials = ruby_client.token_provider.credentials
        
        expect(ruby_credentials.client_id).to eq(test_client_id), "Ruby failed separated store discovery"
        expect(ruby_credentials.token_endpoint).to include('separated.example.com'), "Ruby wrong endpoint from separated stores"
        
        
      ensure
        File.delete(temp_key) if File.exist?(temp_key)
      end
    end
  end
  
  describe 'credential validation' do
    it 'detects invalid or missing private keys' do
      test_client_id = "invalid-key-#{SecureRandom.hex(4)}"
      temp_key = File.join(Dir.tmpdir, "#{test_client_id}.key")
      
      # Write invalid private key content
      File.write(temp_key, "INVALID PRIVATE KEY CONTENT")
      
      begin
        # Test PowerShell behavior with invalid private key using pipe pattern
        ps_invalid_result = `powershell -Command "
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{test_client_id}' -IdentityEndpoint 'https://invalid.example.com/identity' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{test_client_id}' -Name 'Invalid Key Test' -Configuration '#{test_config_name}' | ConvertTo-Json
        "`
        
        if $?.success?
          # PowerShell accepted invalid key and created client - verify object then test Ruby failure
          ps_client = JSON.parse(ps_invalid_result)
          expect(ps_client['Id']).to eq(test_client_id)
          expect(ps_client['Name']).to eq('Invalid Key Test')
          
          # Ruby should fail when trying to use the invalid key
          expect {
            client = Eryph::Compute::Client.new(test_config_name)
            client.token_provider.send(:create_client_assertion)
          }.to raise_error(OpenSSL::PKey::RSAError)
        else
          # PowerShell correctly rejected invalid key - Ruby should also reject
          expect {
            Eryph::Compute::Client.new(test_config_name)
          }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError)
        end
        
      ensure
        File.delete(temp_key) if File.exist?(temp_key)
      end
    end
  end
end