require 'spec_helper'

RSpec.describe Eryph::ClientRuntime do
  let(:mock_environment) { double('Environment') }
  let(:mock_reader) { double('ConfigStoresReader') }
  let(:mock_credentials_lookup) { double('ClientCredentialsLookup') }
  let(:mock_credentials) { build(:credentials) }
  let(:mock_provider_info) { double('LocalIdentityProviderInfo') }

  before do
    allow(Eryph::ClientRuntime::Environment).to receive(:new).and_return(mock_environment)
    allow(Eryph::ClientRuntime::ConfigStoresReader).to receive(:new).and_return(mock_reader)
    allow(Eryph::ClientRuntime::ClientCredentialsLookup).to receive(:new).and_return(mock_credentials_lookup)
    allow(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new).and_return(mock_provider_info)
  end

  describe '.create_credentials_lookup' do
    it 'creates a credentials lookup with default config' do
      expect(Eryph::ClientRuntime::Environment).to receive(:new)
      expect(Eryph::ClientRuntime::ConfigStoresReader).to receive(:new).with(mock_environment)
      expect(Eryph::ClientRuntime::ClientCredentialsLookup).to receive(:new)
        .with(mock_reader, nil)

      result = described_class.create_credentials_lookup

      expect(result).to eq(mock_credentials_lookup)
    end

    it 'creates a credentials lookup with custom config' do
      expect(Eryph::ClientRuntime::ClientCredentialsLookup).to receive(:new)
        .with(mock_reader, 'custom')

      result = described_class.create_credentials_lookup(config_name: 'custom')

      expect(result).to eq(mock_credentials_lookup)
    end
  end

  describe '.credentials_available?' do
    context 'when credentials are found' do
      before do
        allow(mock_credentials_lookup).to receive(:find_credentials).and_return(mock_credentials)
      end

      it 'returns true' do
        expect(described_class).to receive(:create_credentials_lookup)
          .with(config_name: nil)
          .and_return(mock_credentials_lookup)

        result = described_class.credentials_available?

        expect(result).to be true
      end

      it 'uses custom config parameters' do
        expect(described_class).to receive(:create_credentials_lookup)
          .with(config_name: 'custom')
          .and_return(mock_credentials_lookup)

        result = described_class.credentials_available?(config_name: 'custom')

        expect(result).to be true
      end
    end

    context 'when credentials are not found' do
      before do
        allow(mock_credentials_lookup).to receive(:find_credentials).and_raise(Eryph::ClientRuntime::CredentialsNotFoundError)
      end

      it 'returns false for CredentialsNotFoundError' do
        expect(described_class).to receive(:create_credentials_lookup)
          .and_return(mock_credentials_lookup)

        result = described_class.credentials_available?

        expect(result).to be false
      end
    end

    context 'when NoUserCredentialsError is raised' do
      before do
        allow(mock_credentials_lookup).to receive(:find_credentials).and_raise(Eryph::ClientRuntime::NoUserCredentialsError)
      end

      it 'returns false for NoUserCredentialsError' do
        expect(described_class).to receive(:create_credentials_lookup)
          .and_return(mock_credentials_lookup)

        result = described_class.credentials_available?

        expect(result).to be false
      end
    end
  end

  describe '.zero_running?' do
    it 'checks if eryph-zero is running' do
      expect(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
        .with(mock_environment, 'zero')
        .and_return(mock_provider_info)
      expect(mock_provider_info).to receive(:running?).and_return(true)

      result = described_class.zero_running?

      expect(result).to be true
    end

    it 'uses custom identity provider name' do
      expect(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
        .with(mock_environment, 'local')
        .and_return(mock_provider_info)
      expect(mock_provider_info).to receive(:running?).and_return(false)

      result = described_class.zero_running?(identity_provider_name: 'local')

      expect(result).to be false
    end
  end

  describe '.zero_endpoints' do
    let(:mock_endpoints) { { 'identity' => URI.parse('https://localhost:8080/identity'), 'compute' => URI.parse('https://localhost:8080/compute') } }
    let(:expected_endpoints) { { 'identity' => 'https://localhost:8080/identity', 'compute' => 'https://localhost:8080/compute' } }

    it 'returns endpoints when eryph-zero is running' do
      expect(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
        .with(mock_environment, 'zero')
        .and_return(mock_provider_info)
      expect(mock_provider_info).to receive(:running?).and_return(true)
      expect(mock_provider_info).to receive(:endpoints).and_return(mock_endpoints)

      result = described_class.zero_endpoints

      expect(result).to eq(expected_endpoints)
    end

    it 'returns empty hash when eryph-zero is not running' do
      expect(mock_provider_info).to receive(:running?).and_return(false)

      result = described_class.zero_endpoints

      expect(result).to eq({})
    end
  end
end
