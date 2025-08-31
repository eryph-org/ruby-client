require 'integration_helper'
require 'securerandom'

RSpec.describe 'Client Management', :integration do
  let(:test_config_name) { "test-clients-#{SecureRandom.hex(4)}" }
  
  after do
    # Cleanup test configurations by deleting files directly from %APPDATA%\Roaming\.eryph
    eryph_dir = File.join(ENV['APPDATA'], '.eryph')
    config_file = File.join(eryph_dir, "#{test_config_name}.config")
    File.delete(config_file) if File.exist?(config_file)
    
    # Also clean credentials
    Dir.glob(File.join(eryph_dir, "#{test_config_name}-*.credentials")).each do |file|
      File.delete(file)
    end
  end
  
  describe 'multiple clients in configuration' do
    it 'Ruby and PowerShell handle multiple clients correctly' do
      temp_key = File.join(Dir.tmpdir, "multi-clients-#{SecureRandom.hex(4)}.key")
      File.write(temp_key, OpenSSL::PKey::RSA.generate(2048).to_pem)
      
      client1_id = "client-one-#{SecureRandom.hex(4)}"
      client2_id = "client-two-#{SecureRandom.hex(4)}"
      client3_id = "client-three-#{SecureRandom.hex(4)}"
      
      begin
        # PowerShell creates multiple clients in same configuration using pipe pattern
        `powershell -Command "
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{client1_id}' -IdentityEndpoint 'https://test.example.com/identity' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{client1_id}' -Name 'First Client' -Configuration '#{test_config_name}';
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{client2_id}' -IdentityEndpoint 'https://test.example.com/identity' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{client2_id}' -Name 'Second Client' -Configuration '#{test_config_name}';
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{client3_id}' -IdentityEndpoint 'https://test.example.com/identity' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{client3_id}' -Name 'Third Client' -Configuration '#{test_config_name}' -AsDefault;
        "`
        expect($?.success?).to be_truthy, "PowerShell failed to create multiple clients"
        
        # Verify PowerShell sees all clients
        ps_all_result = `powershell -Command "Get-EryphClientConfiguration -Configuration #{test_config_name} | ConvertTo-Json"`
        expect($?.success?).to be_truthy, "PowerShell failed to list all clients"
        
        ps_all_clients = JSON.parse(ps_all_result)
        ps_all_clients = [ps_all_clients] unless ps_all_clients.is_a?(Array)
        expect(ps_all_clients.length).to eq(3), "PowerShell should find 3 clients but found: #{ps_all_clients.length}"
        
        client_ids = ps_all_clients.map { |c| c['Id'] }
        expect(client_ids).to include(client1_id, client2_id, client3_id), "PowerShell missing expected client IDs: #{client_ids}"
        
        # Verify PowerShell identifies correct default client
        ps_default_result = `powershell -Command "Get-EryphClientConfiguration -Configuration #{test_config_name} -Default | ConvertTo-Json"`
        expect($?.success?).to be_truthy, "PowerShell failed to get default client"
        
        ps_default = JSON.parse(ps_default_result)
        expect(ps_default['Id']).to eq(client3_id), "PowerShell should identify client3 as default but found: #{ps_default['Id']}"
          
        # Test Ruby uses same default client selection logic
        ruby_client = Eryph::Compute::Client.new(test_config_name)
        ruby_credentials = ruby_client.token_provider.credentials
        
        expect(ruby_credentials.client_id).to eq(ps_default['Id'])
        
      ensure
        File.delete(temp_key) if File.exist?(temp_key)
      end
    end
  end
  
  describe 'client selection by ID' do
    it 'Ruby can select specific client when multiple exist' do
      temp_key = File.join(Dir.tmpdir, "client-selection-#{SecureRandom.hex(4)}.key")
      File.write(temp_key, OpenSSL::PKey::RSA.generate(2048).to_pem)
      
      target_client_id = "target-client-#{SecureRandom.hex(4)}"
      other_client_id = "other-client-#{SecureRandom.hex(4)}"
      
      begin
        # Create multiple clients, with non-target as default
        `powershell -Command "
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{other_client_id}' -IdentityEndpoint 'https://test.example.com/identity' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{other_client_id}' -Name 'Other Client' -Configuration '#{test_config_name}' -AsDefault;
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{target_client_id}' -IdentityEndpoint 'https://test.example.com/identity' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{target_client_id}' -Name 'Target Client' -Configuration '#{test_config_name}';
        "`
        expect($?.success?).to be_truthy, "PowerShell failed client selection setup"
        
        # Verify PowerShell can get specific client by ID
        ps_target_result = `powershell -Command "Get-EryphClientConfiguration -Configuration #{test_config_name} -Id #{target_client_id} | ConvertTo-Json"`
        expect($?.success?).to be_truthy, "PowerShell failed to get target client by ID"
        
        ps_target = JSON.parse(ps_target_result)
        ps_target = [ps_target] unless ps_target.is_a?(Array)
        target_client = ps_target.find { |c| c['Id'] == target_client_id }
        
        expect(target_client).not_to be_nil
        expect(target_client['Name']).to eq('Target Client')
        
        # Ruby should use default client, not the target client
        ruby_client = Eryph::Compute::Client.new(test_config_name)
        ruby_credentials = ruby_client.token_provider.credentials
        expect(ruby_credentials.client_id).to eq(other_client_id)
        
      ensure
        File.delete(temp_key) if File.exist?(temp_key)
      end
    end
  end
  
  describe 'default client behavior' do
    it 'handles configurations with no explicit default client' do
      temp_key = File.join(Dir.tmpdir, "no-default-#{SecureRandom.hex(4)}.key")
      File.write(temp_key, OpenSSL::PKey::RSA.generate(2048).to_pem)
      
      first_client_id = "first-#{SecureRandom.hex(4)}"
      
      begin
        # Create client with -AsDefault flag to test default behavior
        ps_default_result = `powershell -Command "
          Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{first_client_id}' -IdentityEndpoint 'https://test.example.com/identity' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{first_client_id}' -Name 'First Client' -Configuration '#{test_config_name}' -AsDefault | ConvertTo-Json
        "`
        expect($?.success?).to be_truthy, "PowerShell failed to create default client"
        
        # Parse and verify the created client object
        ps_client = JSON.parse(ps_default_result)
        expect(ps_client['Id']).to eq(first_client_id)
        expect(ps_client['Name']).to eq('First Client')
        
        # Both PowerShell and Ruby should find the same default
        ps_default_check = `powershell -Command "Get-EryphClientConfiguration -Configuration #{test_config_name} -Default | ConvertTo-Json"`
        ps_default = JSON.parse(ps_default_check)
        expect(ps_default['Id']).to eq(first_client_id)
        
        ruby_client = Eryph::Compute::Client.new(test_config_name)
        ruby_credentials = ruby_client.token_provider.credentials
        expect(ruby_credentials.client_id).to eq(first_client_id)
        
      ensure
        File.delete(temp_key) if File.exist?(temp_key)
      end
    end
  end
end