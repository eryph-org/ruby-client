require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::ClientCredentialsLookup do
  let(:mock_environment) { double('Environment') }
  let(:mock_reader) { double('ConfigStoresReader') }
  let(:mock_endpoint_lookup) { double('EndpointLookup') }
  let(:config_name) { 'test' }
  let(:endpoint_name) { 'identity' }
  let(:private_key_content) { build(:rsa_private_key).to_pem }

  before do
    allow(mock_reader).to receive(:environment).and_return(mock_environment)
  end

  subject { described_class.new(mock_reader, mock_endpoint_lookup, config_name, endpoint_name) }

  describe '#initialize' do
    it 'stores all dependencies' do
      lookup = described_class.new(mock_reader, mock_endpoint_lookup, 'custom', 'compute')
      
      expect(lookup.instance_variable_get(:@reader)).to eq(mock_reader)
      expect(lookup.instance_variable_get(:@endpoint_lookup)).to eq(mock_endpoint_lookup)
      expect(lookup.instance_variable_get(:@config_name)).to eq('custom')
      expect(lookup.instance_variable_get(:@endpoint_name)).to eq('compute')
    end

    it 'handles nil endpoint name' do
      lookup = described_class.new(mock_reader, mock_endpoint_lookup, config_name, nil)
      
      expect(lookup.instance_variable_get(:@endpoint_name)).to be_nil
    end
  end

  describe '#credentials_available?' do
    context 'when credentials can be found' do
      before do
        allow(subject).to receive(:find_credentials).and_return(double('ClientCredentials'))
      end

      it 'returns true' do
        result = subject.credentials_available?

        expect(result).to be true
      end
    end

    context 'when credentials cannot be found' do
      before do
        allow(subject).to receive(:find_credentials).and_raise(Eryph::ClientRuntime::CredentialsNotFoundError, 'Not found')
      end

      it 'returns false' do
        result = subject.credentials_available?

        expect(result).to be false
      end
    end
  end

  describe '#find_credentials' do
    let(:mock_config) { double('ConfigStore') }
    let(:mock_clients) { [mock_client] }
    let(:mock_client) { double('ClientConfiguration') }
    let(:mock_credentials) { double('ClientCredentials') }

    context 'when credentials are found' do
      before do
        allow(mock_reader).to receive(:get_default_client).with(config_name).and_return(mock_client_hash)
        allow(mock_reader).to receive(:get_client_private_key).with(mock_client_hash).and_return(private_key_content)
        allow(mock_endpoint_lookup).to receive(:get_endpoint).with('identity').and_return('https://test.eryph.local/identity')
      end

      let(:mock_client_hash) { {'id' => 'test-client', 'name' => 'Test Client'} }
      
      it 'returns the first matching credentials' do
        result = subject.find_credentials

        expect(result).to be_a(Eryph::ClientRuntime::ClientCredentials)
        expect(result.client_id).to eq('test-client')
        expect(result.client_name).to eq('Test Client')
      end

      it 'works with multiple client configurations' do
        # Should use default client first
        allow(mock_reader).to receive(:get_all_clients).with(config_name).and_return([mock_client_hash])
        
        result = subject.find_credentials

        expect(result).to be_a(Eryph::ClientRuntime::ClientCredentials)
        expect(mock_reader).to have_received(:get_default_client).with(config_name)
      end
    end

    context 'when config store is not found' do
      it 'raises CredentialsNotFoundError' do
        allow(mock_reader).to receive(:get_default_client).with(config_name).and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with(config_name).and_return([])

        expect {
          subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, 
                        /No client configuration found for config 'test'/)
      end
    end

    context 'when no client configurations exist' do
      it 'raises CredentialsNotFoundError' do
        allow(mock_reader).to receive(:get_default_client).with(config_name).and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with(config_name).and_return([])

        expect {
          subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, 
                        /No client configuration found for config 'test'/)
      end
    end

    context 'when client configurations is nil' do
      it 'raises CredentialsNotFoundError' do
        allow(mock_reader).to receive(:get_default_client).with(config_name).and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with(config_name).and_return([])

        expect {
          subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, 
                        /No client configuration found for config 'test'/)
      end
    end

    context 'when client private key cannot be retrieved' do
      it 'raises CredentialsNotFoundError' do
        allow(mock_reader).to receive(:get_default_client).with(config_name).and_return({'id' => 'test-client'})
        allow(mock_reader).to receive(:get_client_private_key).and_return(nil)

        expect {
          subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, 
                        /No private key found for client 'test-client'/)
      end
    end

    context 'when get_client_private_key raises an error' do
      it 'raises CredentialsNotFoundError with original error' do
        original_error = StandardError.new("Key file not found")
        allow(mock_reader).to receive(:get_default_client).with(config_name).and_return({'id' => 'test-client'})
        allow(mock_reader).to receive(:get_client_private_key).and_raise(original_error)

        expect {
          subject.find_credentials
        }.to raise_error(StandardError, "Key file not found")
      end
    end

    context 'when get_default_client raises an error' do
      it 'propagates the error' do
        allow(mock_reader).to receive(:get_default_client).and_raise(StandardError.new("Config read error"))

        expect {
          subject.find_credentials
        }.to raise_error(StandardError, "Config read error")
      end
    end

    context 'with different config and endpoint names' do
      subject { described_class.new(mock_reader, mock_endpoint_lookup, 'production', 'compute') }

      it 'uses the correct config name in error messages' do
        allow(mock_reader).to receive(:get_default_client).with('production').and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with('production').and_return([])

        expect {
          subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, 
                        /No client configuration found for config 'production'/)
      end
    end
  end

  describe 'zero configuration support' do
    let(:zero_subject) { described_class.new(mock_reader, mock_endpoint_lookup, 'zero', endpoint_name) }
    let(:mock_provider_info) { double('LocalIdentityProviderInfo') }
    let(:system_credentials) do
      {
        'id' => 'system-client',
        'name' => 'Eryph Zero System Client', 
        'private_key' => build(:rsa_private_key).to_pem,
        'identity_endpoint' => 'https://localhost:8080/identity'
      }
    end

    before do
      allow(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new).and_return(mock_provider_info)
    end

    context 'when zero configuration has system credentials' do
      it 'attempts to use system client credentials' do
        # Mock the normal client lookup methods (fail)
        allow(mock_reader).to receive(:get_default_client).with('zero').and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with('zero').and_return([])
        
        # Then try system credentials (succeeds)
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(system_credentials)
        allow(mock_reader).to receive(:get_client_private_key).and_return(system_credentials['private_key'])
        allow(mock_endpoint_lookup).to receive(:get_endpoint).and_return('https://localhost:8080/connect/token')

        result = zero_subject.find_credentials

        expect(Eryph::ClientRuntime::LocalIdentityProviderInfo).to have_received(:new).at_least(:once)
        expect(mock_provider_info).to have_received(:system_client_credentials).at_least(:once)
        expect(result).not_to be_nil
      end

      it 'creates ClientCredentials from system credentials hash' do
        # Mock the normal client lookup methods (fail)
        allow(mock_reader).to receive(:get_default_client).with('zero').and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with('zero').and_return([])
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(system_credentials)
        allow(mock_reader).to receive(:get_client_private_key).and_return(system_credentials['private_key'])
        allow(mock_endpoint_lookup).to receive(:get_endpoint).and_return(nil)  # Force using direct identity endpoint
        
        mock_system_creds = double('SystemCredentials')
        expect(Eryph::ClientRuntime::ClientCredentials).to receive(:new).with(
          client_id: 'system-client',
          client_name: 'Eryph Zero System Client',
          private_key: system_credentials['private_key'],
          token_endpoint: 'https://localhost:8080/identity/connect/token'
        ).and_return(mock_system_creds)

        result = zero_subject.find_credentials

        expect(result).to eq(mock_system_creds)
      end
    end

    context 'when zero configuration has no system credentials' do
      it 'raises CredentialsNotFoundError' do
        # Mock the normal client lookup methods (fail)
        allow(mock_reader).to receive(:get_default_client).with('zero').and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with('zero').and_return([])
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(nil)

        expect {
          zero_subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, 
                        /No client configuration found for config 'zero'/)
      end
    end

    context 'when system credentials are invalid' do
      it 'raises CredentialsNotFoundError for missing id' do
        invalid_credentials = system_credentials.except('id')
        # Mock the normal client lookup methods (fail)
        allow(mock_reader).to receive(:get_default_client).with('zero').and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with('zero').and_return([])
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(invalid_credentials)
        allow(mock_reader).to receive(:get_client_private_key).and_return(private_key_content)
        allow(mock_endpoint_lookup).to receive(:get_endpoint).and_return('https://localhost:8080/connect/token')

        expect {
          zero_subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, 
                        /Invalid credentials found/)
      end

      it 'raises CredentialsNotFoundError for missing private_key' do
        invalid_credentials = system_credentials.except('private_key')
        # Mock the normal client lookup methods (fail)
        allow(mock_reader).to receive(:get_default_client).with('zero').and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with('zero').and_return([])
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(invalid_credentials)
        allow(mock_reader).to receive(:get_client_private_key).and_return(nil)
        allow(mock_endpoint_lookup).to receive(:get_endpoint).and_return('https://localhost:8080/connect/token')

        expect {
          zero_subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, 
                        /No private key found for client/)
      end

      it 'raises CredentialsNotFoundError for missing identity_endpoint' do
        invalid_credentials = system_credentials.except('identity_endpoint')
        # Mock the normal client lookup methods (fail)
        allow(mock_reader).to receive(:get_default_client).with('zero').and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with('zero').and_return([])
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(invalid_credentials)
        allow(mock_reader).to receive(:get_client_private_key).and_return(private_key_content)
        allow(mock_endpoint_lookup).to receive(:get_endpoint).and_return(nil)

        expect {
          zero_subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, 
                        /No identity endpoint found for config/)
      end
    end

    context 'when LocalIdentityProviderInfo creation fails' do
      it 'propagates the error' do
        # Mock the normal client lookup methods (fail)
        allow(mock_reader).to receive(:get_default_client).with('zero').and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with('zero').and_return([])
        allow(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
          .and_raise(StandardError.new("Provider error"))

        expect {
          zero_subject.find_credentials
        }.to raise_error(StandardError, "Provider error")
      end
    end
  end

  describe 'non-zero configuration' do
    it 'does not attempt system credentials for non-zero configs' do
      allow(mock_reader).to receive(:get_default_client).with(config_name).and_return(nil)
      allow(mock_reader).to receive(:get_all_clients).with(config_name).and_return([])

      expect(Eryph::ClientRuntime::LocalIdentityProviderInfo).not_to receive(:new)

      expect {
        subject.find_credentials
      }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError)
    end
  end

  describe '#find_token_endpoint (private)' do
    context 'for zero configuration' do
      let(:zero_subject) { described_class.new(mock_reader, mock_endpoint_lookup, 'zero', endpoint_name) }

      it 'uses direct identity endpoint from system client' do
        client_with_endpoint = {
          'id' => 'system-client',
          '_identity_endpoint' => 'https://localhost:8080/identity'
        }
        allow(zero_subject).to receive(:find_client).and_return(client_with_endpoint)

        result = zero_subject.send(:find_token_endpoint)

        expect(result).to eq('https://localhost:8080/identity/connect/token')
      end

      it 'strips trailing slash from identity endpoint' do
        client_with_endpoint = {
          'id' => 'system-client',
          '_identity_endpoint' => 'https://localhost:8080/identity/'
        }
        allow(zero_subject).to receive(:find_client).and_return(client_with_endpoint)

        result = zero_subject.send(:find_token_endpoint)

        expect(result).to eq('https://localhost:8080/identity/connect/token')
      end

      it 'falls back to endpoint lookup when no direct endpoint' do
        client_without_endpoint = { 'id' => 'system-client' }
        allow(zero_subject).to receive(:find_client).and_return(client_without_endpoint)
        allow(zero_subject).to receive(:determine_endpoint_name).and_return('identity')
        allow(mock_endpoint_lookup).to receive(:get_endpoint).with('identity').and_return('https://fallback.example.com')

        result = zero_subject.send(:find_token_endpoint)

        expect(result).to eq('https://fallback.example.com/connect/token')
      end

      it 'falls back to endpoint lookup when client is nil' do
        allow(zero_subject).to receive(:find_client).and_return(nil)
        allow(zero_subject).to receive(:determine_endpoint_name).and_return('identity')
        allow(mock_endpoint_lookup).to receive(:get_endpoint).with('identity').and_return('https://fallback.example.com')

        result = zero_subject.send(:find_token_endpoint)

        expect(result).to eq('https://fallback.example.com/connect/token')
      end
    end

    context 'for regular configuration' do
      it 'uses endpoint lookup with provided endpoint name' do
        lookup_with_endpoint = described_class.new(mock_reader, mock_endpoint_lookup, config_name, 'custom-endpoint')
        allow(mock_endpoint_lookup).to receive(:get_endpoint).with('custom-endpoint').and_return('https://custom.example.com')

        result = lookup_with_endpoint.send(:find_token_endpoint)

        expect(result).to eq('https://custom.example.com/connect/token')
      end

      it 'uses endpoint lookup with determined endpoint name when none provided' do
        lookup_without_endpoint = described_class.new(mock_reader, mock_endpoint_lookup, config_name, nil)
        allow(lookup_without_endpoint).to receive(:determine_endpoint_name).and_return('identity')
        allow(mock_endpoint_lookup).to receive(:get_endpoint).with('identity').and_return('https://determined.example.com')

        result = lookup_without_endpoint.send(:find_token_endpoint)

        expect(result).to eq('https://determined.example.com/connect/token')
      end

      it 'strips trailing slash from endpoint URL' do
        allow(mock_endpoint_lookup).to receive(:get_endpoint).with(endpoint_name).and_return('https://example.com/')

        result = subject.send(:find_token_endpoint)

        expect(result).to eq('https://example.com/connect/token')
      end

      it 'returns nil when endpoint lookup fails' do
        allow(mock_endpoint_lookup).to receive(:get_endpoint).with(endpoint_name).and_return(nil)

        result = subject.send(:find_token_endpoint)

        expect(result).to be_nil
      end
    end
  end

  describe '#determine_endpoint_name (private)' do
    it 'returns identity for zero configuration' do
      zero_subject = described_class.new(mock_reader, mock_endpoint_lookup, 'zero', nil)

      result = zero_subject.send(:determine_endpoint_name)

      expect(result).to eq('identity')
    end

    it 'returns identity for ZERO configuration (case insensitive)' do
      zero_subject = described_class.new(mock_reader, mock_endpoint_lookup, 'ZERO', nil)

      result = zero_subject.send(:determine_endpoint_name)

      expect(result).to eq('identity')
    end

    it 'returns identity for regular configuration' do
      result = subject.send(:determine_endpoint_name)

      expect(result).to eq('identity')
    end

    it 'returns identity for custom configuration names' do
      custom_subject = described_class.new(mock_reader, mock_endpoint_lookup, 'production', nil)

      result = custom_subject.send(:determine_endpoint_name)

      expect(result).to eq('identity')
    end
  end

  describe '#find_zero_client (private)' do
    let(:zero_subject) { described_class.new(mock_reader, mock_endpoint_lookup, 'zero', endpoint_name) }
    let(:mock_provider_info) { double('LocalIdentityProviderInfo') }
    let(:system_credentials) do
      {
        'id' => 'system-client',
        'name' => 'Eryph Zero System Client',
        'private_key' => 'test_private_key',
        'identity_endpoint' => 'https://localhost:8080/identity'
      }
    end

    before do
      allow(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
        .with(mock_reader.environment, 'zero')
        .and_return(mock_provider_info)
    end

    context 'when identity provider is running' do
      before do
        allow(mock_provider_info).to receive(:running?).and_return(true)
      end

      it 'creates virtual store for system client credentials' do
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(system_credentials)

        result = zero_subject.send(:find_zero_client)

        expect(result['id']).to eq('system-client')
        expect(result['name']).to eq('Eryph Zero System Client')
        expect(result['_identity_endpoint']).to eq('https://localhost:8080/identity')
        expect(result['_store']).to be_truthy
      end

      it 'virtual store returns private key for correct client ID' do
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(system_credentials)

        result = zero_subject.send(:find_zero_client)
        virtual_store = result['_store']

        private_key = virtual_store.get_private_key('system-client')
        expect(private_key).to eq('test_private_key')
      end

      it 'virtual store returns nil for incorrect client ID' do
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(system_credentials)

        result = zero_subject.send(:find_zero_client)
        virtual_store = result['_store']

        private_key = virtual_store.get_private_key('wrong-id')
        expect(private_key).to be_nil
      end

      it 'returns nil when system client credentials unavailable' do
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(nil)

        result = zero_subject.send(:find_zero_client)

        expect(result).to be_nil
      end
    end

    context 'when identity provider is not running' do
      it 'returns nil' do
        allow(mock_provider_info).to receive(:running?).and_return(false)

        result = zero_subject.send(:find_zero_client)

        expect(result).to be_nil
      end
    end
  end

  describe 'complete integration scenarios' do
    let(:zero_subject) { described_class.new(mock_reader, mock_endpoint_lookup, 'zero', endpoint_name) }

    context 'zero configuration with running identity provider' do
      let(:mock_provider_info) { double('LocalIdentityProviderInfo') }
      let(:system_credentials) do
        {
          'id' => 'system-client',
          'name' => 'Eryph Zero System Client',
          'private_key' => build(:rsa_private_key).to_pem,
          'identity_endpoint' => 'https://localhost:8080/identity'
        }
      end

      before do
        # Mock the regular config lookup to fail
        allow(mock_reader).to receive(:get_default_client).with('zero').and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).with('zero').and_return([])

        # Mock the zero-config fallback to succeed
        allow(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
          .with(mock_reader.environment, 'zero')
          .and_return(mock_provider_info)
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:system_client_credentials).and_return(system_credentials)
        
        # Mock get_client_private_key for any client hash (including the system client virtual hash)
        allow(mock_reader).to receive(:get_client_private_key).and_return(private_key_content)
      end

      it 'successfully creates credentials from system client' do
        result = zero_subject.find_credentials

        expect(result).to be_a(Eryph::ClientRuntime::ClientCredentials)
        expect(result.client_id).to eq('system-client')
        expect(result.client_name).to eq('Eryph Zero System Client')
        expect(result.token_endpoint).to eq('https://localhost:8080/identity/connect/token')
      end
    end

    context 'error scenarios in find_credentials' do
      before do
        allow(mock_reader).to receive(:get_default_client).and_return(mock_client_hash)
        allow(mock_reader).to receive(:get_client_private_key).and_return('valid-key')
        allow(mock_endpoint_lookup).to receive(:get_endpoint).and_return('https://example.com')
      end

      let(:mock_client_hash) { { 'id' => 'test-client', 'name' => 'Test Client' } }

      it 'raises error when ClientCredentials construction fails' do
        # Mock ClientCredentials to raise ArgumentError
        allow(Eryph::ClientRuntime::ClientCredentials).to receive(:new)
          .and_raise(ArgumentError.new('Invalid key format'))

        expect {
          subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, /Invalid credentials found: Invalid key format/)
      end

      it 'raises error when no private key found' do
        allow(mock_reader).to receive(:get_client_private_key).and_return(nil)

        expect {
          subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, /No private key found for client 'test-client'/)
      end

      it 'raises error when no token endpoint found' do
        allow(mock_endpoint_lookup).to receive(:get_endpoint).and_return(nil)

        expect {
          subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, /No identity endpoint found for config 'test'/)
      end

      it 'raises error when no client configuration found' do
        allow(mock_reader).to receive(:get_default_client).and_return(nil)
        allow(mock_reader).to receive(:get_all_clients).and_return([])

        expect {
          subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, /No client configuration found for config 'test'/)
      end
    end
  end
end