require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::ClientCredentialsLookup do
  let(:mock_environment) { double('Environment') }
  let(:mock_reader) { double('ConfigStoresReader') }
  let(:config_name) { 'test' }
  let(:private_key_content) { build(:rsa_private_key).to_pem }
  let(:mock_client_data) do
    {
      'id' => 'test-client-id',
      'name' => 'My Client'
    }
  end

  before do
    allow(mock_reader).to receive(:environment).and_return(mock_environment)
    allow(mock_environment).to receive(:windows?).and_return(true)
    allow(mock_environment).to receive(:linux?).and_return(false)
  end

  describe '#initialize' do
    context 'with config name' do
      subject { described_class.new(mock_reader, config_name) }

      it 'stores reader and config name' do
        expect(subject.reader).to eq(mock_reader)
        expect(subject.config_name).to eq(config_name)
      end
    end

    context 'without config name (automatic discovery)' do
      subject { described_class.new(mock_reader) }

      it 'stores reader with nil config name' do
        expect(subject.reader).to eq(mock_reader)
        expect(subject.config_name).to be_nil
      end
    end
  end

  describe '#find_credentials' do
    context 'with specific config name' do
      subject { described_class.new(mock_reader, config_name) }

      context 'when default client exists' do
        before do
          allow(subject).to receive(:get_default_credentials).and_return(build(:client_credentials))
        end

        it 'returns credentials' do
          result = subject.find_credentials
          expect(result).to be_a(Eryph::ClientRuntime::ClientCredentials)
        end
      end

      context 'when no default client exists' do
        before do
          allow(subject).to receive(:get_default_credentials).and_return(nil)
        end

        it 'raises CredentialsNotFoundError' do
          expect { subject.find_credentials }.to raise_error(
            Eryph::ClientRuntime::CredentialsNotFoundError,
            "No default client found in configuration 'test'"
          )
        end
      end
    end

    context 'without config name (automatic discovery)' do
      subject { described_class.new(mock_reader) }

      context 'on Windows' do
        before do
          allow(mock_environment).to receive(:windows?).and_return(true)
        end

        it 'tries default, zero, local configs in order' do
          expect(subject).to receive(:find_credentials_in_configs).with('default', 'zero', 'local')
          subject.find_credentials
        end
      end

      context 'on Unix' do
        before do
          allow(mock_environment).to receive(:windows?).and_return(false)
        end

        it 'tries default, local configs in order' do
          expect(subject).to receive(:find_credentials_in_configs).with('default', 'local')
          subject.find_credentials
        end
      end
    end
  end

  describe '#find_credentials_in_configs' do
    subject { described_class.new(mock_reader) }

    context 'when first config has credentials' do
      before do
        allow(subject).to receive(:get_default_credentials).with('default').and_return(build(:client_credentials))
      end

      it 'returns credentials from first config' do
        result = subject.find_credentials_in_configs('default', 'zero')
        expect(result).to be_a(Eryph::ClientRuntime::ClientCredentials)
      end

      it 'does not check subsequent configs' do
        expect(subject).not_to receive(:get_default_credentials).with('zero')
        subject.find_credentials_in_configs('default', 'zero')
      end
    end

    context 'when no config has credentials' do
      before do
        allow(subject).to receive(:get_default_credentials).and_return(nil)
        allow(subject).to receive(:get_system_client_credentials).and_return(nil)
      end

      it 'raises NoUserCredentialsError' do
        expect { subject.find_credentials_in_configs('default', 'zero') }.to raise_error(
          Eryph::ClientRuntime::NoUserCredentialsError,
          'No credentials found. Please configure an eryph client.'
        )
      end
    end

    context 'when zero config has system client' do
      before do
        allow(subject).to receive(:get_default_credentials).and_return(nil)
        allow(subject).to receive(:get_system_client_credentials).with('zero').and_return(build(:client_credentials))
      end

      it 'returns system client credentials' do
        result = subject.find_credentials_in_configs('default', 'zero')
        expect(result).to be_a(Eryph::ClientRuntime::ClientCredentials)
      end
    end
  end

  describe '#get_default_credentials' do
    subject { described_class.new(mock_reader, config_name) }

    context 'when client exists' do
      before do
        allow(mock_reader).to receive(:get_default_client).and_return(mock_client_data)
        allow(subject).to receive(:build_credentials).and_return(build(:client_credentials))
      end

      it 'builds and returns credentials' do
        result = subject.get_default_credentials(config_name)
        expect(result).to be_a(Eryph::ClientRuntime::ClientCredentials)
      end
    end

    context 'when client does not exist' do
      before do
        allow(mock_reader).to receive(:get_default_client).and_return(nil)
      end

      it 'returns nil' do
        result = subject.get_default_credentials(config_name)
        expect(result).to be_nil
      end
    end
  end

  describe '#get_credentials_by_client_id' do
    subject { described_class.new(mock_reader, config_name) }
    let(:client_id) { 'specific-client' }

    context 'when client exists' do
      before do
        allow(mock_reader).to receive(:get_client).and_return(mock_client_data)
        allow(subject).to receive(:build_credentials).and_return(build(:client_credentials))
      end

      it 'builds and returns credentials' do
        result = subject.get_credentials_by_client_id(client_id, config_name)
        expect(result).to be_a(Eryph::ClientRuntime::ClientCredentials)
      end
    end

    context 'when client does not exist' do
      before do
        allow(mock_reader).to receive(:get_client).and_return(nil)
      end

      it 'returns nil' do
        result = subject.get_credentials_by_client_id(client_id, config_name)
        expect(result).to be_nil
      end
    end
  end

  describe '#get_credentials_by_client_name' do
    subject { described_class.new(mock_reader, config_name) }
    let(:client_name) { 'My Client' }

    context 'when client exists' do
      before do
        allow(mock_reader).to receive(:get_all_clients).and_return([mock_client_data])
        allow(subject).to receive(:build_credentials).and_return(build(:client_credentials))
      end

      it 'builds and returns credentials' do
        result = subject.get_credentials_by_client_name(client_name, config_name)
        expect(result).to be_a(Eryph::ClientRuntime::ClientCredentials)
      end
    end

    context 'when client does not exist' do
      before do
        allow(mock_reader).to receive(:get_all_clients).and_return([])
      end

      it 'returns nil' do
        result = subject.get_credentials_by_client_name(client_name, config_name)
        expect(result).to be_nil
      end
    end
  end

  describe '#get_system_client_credentials' do
    subject { described_class.new(mock_reader) }

    context 'for zero config on Windows' do
      before do
        allow(mock_environment).to receive(:windows?).and_return(true)
        allow(mock_environment).to receive(:linux?).and_return(false)
        allow(mock_environment).to receive(:admin_user?).and_return(true)
      end

      context 'when eryph-zero is running' do
        let(:mock_provider_info) { double('LocalIdentityProviderInfo') }
        let(:system_creds) do
          {
            'id' => 'system-client',
            'identity_endpoint' => 'https://localhost:8080/identity',
            'private_key' => build(:rsa_private_key)
          }
        end

        before do
          allow(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new).and_return(mock_provider_info)
          allow(mock_provider_info).to receive(:running?).and_return(true)
          allow(mock_provider_info).to receive(:system_client_credentials).and_return(system_creds)
        end

        it 'returns system client credentials' do
          result = subject.get_system_client_credentials('zero')
          expect(result).to be_a(Eryph::ClientRuntime::ClientCredentials)
          expect(result.client_id).to eq('system-client')
        end
      end

      context 'when not running as admin' do
        before do
          allow(mock_environment).to receive(:admin_user?).and_return(false)
        end

        it 'raises NoUserCredentialsError with admin message' do
          expect { subject.get_system_client_credentials('zero') }.to raise_error(
            Eryph::ClientRuntime::NoUserCredentialsError,
            /requires Administrator privileges/
          )
        end
      end
    end

    context 'for unsupported config' do
      it 'returns nil' do
        result = subject.get_system_client_credentials('unsupported')
        expect(result).to be_nil
      end
    end
  end

  describe '#credentials_available?' do
    subject { described_class.new(mock_reader, config_name) }

    context 'when credentials can be found' do
      before do
        allow(subject).to receive(:find_credentials).and_return(build(:client_credentials))
      end

      it 'returns true' do
        result = subject.credentials_available?
        expect(result).to be true
      end
    end

    context 'when credentials cannot be found' do
      before do
        allow(subject).to receive(:find_credentials).and_raise(Eryph::ClientRuntime::CredentialsNotFoundError)
      end

      it 'returns false' do
        result = subject.credentials_available?
        expect(result).to be false
      end
    end

    context 'when NoUserCredentialsError is raised' do
      before do
        allow(subject).to receive(:find_credentials).and_raise(Eryph::ClientRuntime::NoUserCredentialsError)
      end

      it 'returns false' do
        result = subject.credentials_available?
        expect(result).to be false
      end
    end
  end

  describe 'ClientCredentials constructor validation' do
    let(:valid_params) do
      {
        client_id: 'test-client',
        private_key: test_rsa_key,
        token_endpoint: 'https://test.eryph.local/identity/connect/token',
        configuration: 'test'
      }
    end

    it 'raises ArgumentError for nil client_id' do
      expect {
        Eryph::ClientRuntime::ClientCredentials.new(
          client_id: nil,
          client_name: 'Test Client',
          private_key: private_key_content,
          token_endpoint: 'https://test.eryph.local/identity/connect/token',
          configuration: 'test'
        )
      }.to raise_error(ArgumentError, /client_id cannot be nil or empty/)
    end

    it 'raises ArgumentError for empty client_id' do
      expect {
        Eryph::ClientRuntime::ClientCredentials.new(
          client_id: '',
          client_name: 'Test Client',
          private_key: private_key_content,
          token_endpoint: 'https://test.eryph.local/identity/connect/token',
          configuration: 'test'
        )
      }.to raise_error(ArgumentError, /client_id cannot be nil or empty/)
    end

    it 'raises ArgumentError for nil token_endpoint' do
      expect {
        Eryph::ClientRuntime::ClientCredentials.new(
          client_id: 'test-client',
          client_name: 'Test Client',
          private_key: private_key_content,
          token_endpoint: nil,
          configuration: 'test'
        )
      }.to raise_error(ArgumentError, /token_endpoint cannot be nil or empty/)
    end

    it 'raises ArgumentError for nil private_key' do
      expect {
        Eryph::ClientRuntime::ClientCredentials.new(
          client_id: 'test-client',
          client_name: 'Test Client',
          private_key: nil,
          token_endpoint: 'https://test.eryph.local/identity/connect/token',
          configuration: 'test'
        )
      }.to raise_error(ArgumentError, /private_key cannot be nil/)
    end

    it 'raises ArgumentError for empty private_key string' do
      expect {
        Eryph::ClientRuntime::ClientCredentials.new(
          client_id: 'test-client',
          client_name: 'Test Client',
          private_key: '',
          token_endpoint: 'https://test.eryph.local/identity/connect/token',
          configuration: 'test'
        )
      }.to raise_error(ArgumentError, /private_key cannot be empty/)
    end

    it 'raises ArgumentError for invalid private_key format' do
      expect {
        Eryph::ClientRuntime::ClientCredentials.new(
          client_id: 'test-client',
          client_name: 'Test Client',
          private_key: 'invalid-key-format',
          token_endpoint: 'https://test.eryph.local/identity/connect/token',
          configuration: 'test'
        )
      }.to raise_error(ArgumentError, /Invalid RSA private key/)
    end
  end

  describe 'system client edge cases' do
    subject { described_class.new(mock_reader) }

    context 'for zero config on non-Windows platform' do
      before do
        allow(mock_environment).to receive(:windows?).and_return(false)
        allow(mock_environment).to receive(:linux?).and_return(true)
      end

      it 'returns nil when zero config requested on Linux' do
        result = subject.send(:get_system_client_credentials, 'zero')
        expect(result).to be_nil
      end
    end

    context 'for Windows admin privilege checking' do
      before do
        allow(mock_environment).to receive(:windows?).and_return(true)
        allow(mock_environment).to receive(:linux?).and_return(false)
        allow(mock_environment).to receive(:admin_user?).and_return(false)
      end

      it 'raises NoUserCredentialsError when Windows user is not admin' do
        expect {
          subject.send(:get_system_client_credentials, 'zero')
        }.to raise_error(Eryph::ClientRuntime::NoUserCredentialsError, /requires Administrator privileges/)
      end
    end

    context 'for Linux root privilege checking' do
      before do
        allow(mock_environment).to receive(:windows?).and_return(false)
        allow(mock_environment).to receive(:linux?).and_return(true)
        allow(mock_environment).to receive(:admin_user?).and_return(false)
      end

      it 'raises NoUserCredentialsError when Linux user is not root' do
        expect {
          subject.send(:get_system_client_credentials, 'local')
        }.to raise_error(Eryph::ClientRuntime::NoUserCredentialsError, /requires root privileges/)
      end
    end

    context 'for unsupported OS' do
      before do
        allow(mock_environment).to receive(:windows?).and_return(false)
        allow(mock_environment).to receive(:linux?).and_return(false)
      end

      it 'returns nil for unsupported operating system' do
        result = subject.send(:get_system_client_credentials, 'zero')
        expect(result).to be_nil
      end
    end

    context 'for unsupported config names' do
      before do
        allow(mock_environment).to receive(:windows?).and_return(true)
      end

      it 'returns nil for default config' do
        result = subject.send(:get_system_client_credentials, 'default')
        expect(result).to be_nil
      end

      it 'returns nil for custom config' do
        result = subject.send(:get_system_client_credentials, 'custom')
        expect(result).to be_nil
      end
    end

    context 'when provider is not running' do
      before do
        allow(mock_environment).to receive(:windows?).and_return(true)
        allow(mock_environment).to receive(:admin_user?).and_return(true)
        
        provider_info = double('LocalIdentityProviderInfo', running?: false)
        allow(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new).and_return(provider_info)
      end

      it 'returns nil when identity provider is not running' do
        result = subject.send(:get_system_client_credentials, 'zero')
        expect(result).to be_nil
      end
    end

    context 'when system credentials are not available' do
      before do
        allow(mock_environment).to receive(:windows?).and_return(true)
        allow(mock_environment).to receive(:admin_user?).and_return(true)
        
        provider_info = double('LocalIdentityProviderInfo', running?: true, system_client_credentials: nil)
        allow(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new).and_return(provider_info)
      end

      it 'returns nil when system credentials are not available' do
        result = subject.send(:get_system_client_credentials, 'zero')
        expect(result).to be_nil
      end
    end
  end

  describe 'build_credentials edge cases' do
    subject { described_class.new(mock_reader) }
    
    let(:test_client) { { 'id' => 'test-client', 'name' => 'Test Client' } }

    context 'when private key is not available' do
      before do
        allow(mock_reader).to receive(:get_client_private_key).with(test_client).and_return(nil)
      end

      it 'returns nil when private key cannot be retrieved' do
        result = subject.send(:build_credentials, test_client, 'test')
        expect(result).to be_nil
      end
    end

    context 'when token endpoint is not available' do
      before do
        allow(mock_reader).to receive(:get_client_private_key).with(test_client).and_return(private_key_content)
        allow(subject).to receive(:get_token_endpoint).with('test').and_return(nil)
      end

      it 'returns nil when token endpoint cannot be retrieved' do
        result = subject.send(:build_credentials, test_client, 'test')
        expect(result).to be_nil
      end
    end

    context 'when ClientCredentials constructor raises ArgumentError' do
      before do
        allow(mock_reader).to receive(:get_client_private_key).with(test_client).and_return(private_key_content)
        allow(subject).to receive(:get_token_endpoint).with('test').and_return('https://test.local/token')
        
        # Mock ClientCredentials.new to raise ArgumentError
        allow(Eryph::ClientRuntime::ClientCredentials).to receive(:new).and_raise(ArgumentError, 'Invalid credentials')
      end

      it 'returns nil when credentials construction fails' do
        result = subject.send(:build_credentials, test_client, 'test')
        expect(result).to be_nil
      end
    end
  end

  describe 'get_token_endpoint edge cases' do
    subject { described_class.new(mock_reader) }

    context 'when endpoint lookup fails' do
      before do
        endpoint_lookup = double('EndpointLookup', get_endpoint: nil)
        allow(Eryph::ClientRuntime::EndpointLookup).to receive(:new).and_return(endpoint_lookup)
      end

      it 'returns nil when identity endpoint cannot be found' do
        result = subject.send(:get_token_endpoint, 'test')
        expect(result).to be_nil
      end
    end
  end

  describe 'zero config specific error paths' do
    subject { described_class.new(mock_reader, 'zero') }

    context 'when zero config has no default client but system client unavailable' do
      before do
        allow(mock_reader).to receive(:get_default_client).with('zero').and_return(nil)
        allow(mock_environment).to receive(:windows?).and_return(true)
        allow(subject).to receive(:get_system_client_credentials).and_return(nil)
      end

      it 'raises CredentialsNotFoundError' do
        expect {
          subject.find_credentials
        }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, /No default client found in configuration 'zero'/)
      end
    end
  end
end