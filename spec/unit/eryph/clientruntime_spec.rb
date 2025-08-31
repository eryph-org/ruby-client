require 'spec_helper'

RSpec.describe Eryph::ClientRuntime do
  let(:mock_environment) { double('Environment') }
  let(:mock_reader) { double('ConfigStoresReader') }
  let(:mock_endpoint_lookup) { double('EndpointLookup') }
  let(:mock_credentials_lookup) { double('ClientCredentialsLookup') }
  let(:mock_credentials) { build(:credentials) }
  let(:mock_token_provider) { double('TokenProvider') }
  let(:mock_provider_info) { double('LocalIdentityProviderInfo') }

  before do
    allow(Eryph::ClientRuntime::Environment).to receive(:new).and_return(mock_environment)
    allow(Eryph::ClientRuntime::ConfigStoresReader).to receive(:new).and_return(mock_reader)
    allow(Eryph::ClientRuntime::EndpointLookup).to receive(:new).and_return(mock_endpoint_lookup)
    allow(Eryph::ClientRuntime::ClientCredentialsLookup).to receive(:new).and_return(mock_credentials_lookup)
    allow(Eryph::ClientRuntime::TokenProvider).to receive(:new).and_return(mock_token_provider)
    allow(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new).and_return(mock_provider_info)
  end

  describe '.create_credentials_lookup' do
    it 'creates a credentials lookup with default config' do
      expect(Eryph::ClientRuntime::Environment).to receive(:new)
      expect(Eryph::ClientRuntime::ConfigStoresReader).to receive(:new).with(mock_environment)
      expect(Eryph::ClientRuntime::EndpointLookup).to receive(:new).with(mock_reader, 'default')
      expect(Eryph::ClientRuntime::ClientCredentialsLookup).to receive(:new)
        .with(mock_reader, mock_endpoint_lookup, 'default', nil)

      result = described_class.create_credentials_lookup

      expect(result).to eq(mock_credentials_lookup)
    end

    it 'creates a credentials lookup with custom config and endpoint' do
      expect(Eryph::ClientRuntime::EndpointLookup).to receive(:new).with(mock_reader, 'custom')
      expect(Eryph::ClientRuntime::ClientCredentialsLookup).to receive(:new)
        .with(mock_reader, mock_endpoint_lookup, 'custom', 'compute')

      result = described_class.create_credentials_lookup(config_name: 'custom', endpoint_name: 'compute')

      expect(result).to eq(mock_credentials_lookup)
    end
  end

  describe '.get_access_token' do
    before do
      allow(mock_credentials_lookup).to receive(:find_credentials).and_return(mock_credentials)
      allow(mock_token_provider).to receive(:get_access_token).and_return('test_token_123')
    end

    it 'gets access token with default parameters' do
      expect(described_class).to receive(:create_credentials_lookup)
        .with(config_name: 'default', endpoint_name: nil, environment: nil)
        .and_return(mock_credentials_lookup)
      
      expect(Eryph::ClientRuntime::TokenProvider).to receive(:new)
        .with(mock_credentials, scopes: ['compute:read', 'compute:write'])

      result = described_class.get_access_token

      expect(result).to eq('test_token_123')
    end

    it 'gets access token with custom parameters' do
      expect(described_class).to receive(:create_credentials_lookup)
        .with(config_name: 'test', endpoint_name: 'identity', environment: nil)
        .and_return(mock_credentials_lookup)
      
      expect(Eryph::ClientRuntime::TokenProvider).to receive(:new)
        .with(mock_credentials, scopes: ['custom:scope'])

      result = described_class.get_access_token(
        config_name: 'test',
        endpoint_name: 'identity', 
        scopes: ['custom:scope']
      )

      expect(result).to eq('test_token_123')
    end

    it 'raises error when credentials lookup fails' do
      allow(mock_credentials_lookup).to receive(:find_credentials)
        .and_raise(Eryph::ClientRuntime::CredentialsNotFoundError, 'No credentials')

      expect {
        described_class.get_access_token
      }.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, 'No credentials')
    end
  end

  describe '.credentials_available?' do
    context 'when credentials are found' do
      it 'returns true' do
        allow(mock_credentials_lookup).to receive(:find_credentials).and_return(mock_credentials)

        result = described_class.credentials_available?

        expect(result).to be true
      end
    end

    context 'when credentials are not found' do
      it 'returns false' do
        allow(mock_credentials_lookup).to receive(:find_credentials)
          .and_raise(Eryph::ClientRuntime::CredentialsNotFoundError)

        result = described_class.credentials_available?

        expect(result).to be false
      end
    end

    context 'when other error occurs during lookup' do
      it 'propagates the error' do
        allow(mock_credentials_lookup).to receive(:find_credentials)
          .and_raise(StandardError, 'Unexpected error')

        expect {
          described_class.credentials_available?
        }.to raise_error(StandardError, 'Unexpected error')
      end
    end

    it 'uses custom config parameters' do
      allow(mock_credentials_lookup).to receive(:find_credentials).and_return(mock_credentials)
      
      expect(described_class).to receive(:create_credentials_lookup)
        .with(config_name: 'test', endpoint_name: 'compute')
        .and_return(mock_credentials_lookup)

      result = described_class.credentials_available?(config_name: 'test', endpoint_name: 'compute')

      expect(result).to be true
    end
  end

  describe '.zero_running?' do
    before do
      allow(mock_provider_info).to receive(:running?).and_return(true)
    end

    it 'checks if zero is running with default provider name' do
      expect(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
        .with(mock_environment, 'zero')
        .and_return(mock_provider_info)

      result = described_class.zero_running?

      expect(result).to be true
    end

    it 'checks if custom provider is running' do
      allow(mock_provider_info).to receive(:running?).and_return(false)
      
      expect(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
        .with(mock_environment, 'custom-provider')
        .and_return(mock_provider_info)

      result = described_class.zero_running?(identity_provider_name: 'custom-provider')

      expect(result).to be false
    end
  end

  describe '.zero_endpoints' do
    let(:mock_endpoints) do
      {
        'identity' => URI.parse('https://localhost:8080/identity'),
        'compute' => URI.parse('https://localhost:8080/compute')
      }
    end

    context 'when provider is running' do
      before do
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:endpoints).and_return(mock_endpoints)
      end

      it 'returns endpoint strings with default provider' do
        expect(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
          .with(mock_environment, 'zero')

        result = described_class.zero_endpoints

        expected = {
          'identity' => 'https://localhost:8080/identity',
          'compute' => 'https://localhost:8080/compute'
        }
        expect(result).to eq(expected)
      end

      it 'returns endpoint strings with custom provider' do
        expect(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
          .with(mock_environment, 'test-provider')

        result = described_class.zero_endpoints(identity_provider_name: 'test-provider')

        expected = {
          'identity' => 'https://localhost:8080/identity',
          'compute' => 'https://localhost:8080/compute'
        }
        expect(result).to eq(expected)
      end
    end

    context 'when provider is not running' do
      before do
        allow(mock_provider_info).to receive(:running?).and_return(false)
      end

      it 'returns empty hash' do
        result = described_class.zero_endpoints

        expect(result).to eq({})
      end
    end
  end
end