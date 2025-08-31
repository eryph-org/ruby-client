require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::EndpointLookup do
  let(:mock_reader) { double('ConfigStoresReader') }
  let(:config_name) { 'test' }
  let(:mock_environment) { double('Environment') }
  
  subject { described_class.new(mock_reader, config_name) }

  before do
    allow(mock_reader).to receive(:environment).and_return(mock_environment)
  end

  describe '#initialize' do
    it 'stores reader and config name' do
      lookup = described_class.new(mock_reader, 'production')
      
      expect(lookup.reader).to eq(mock_reader)
      expect(lookup.config_name).to eq('production')
    end
  end

  describe '#get_endpoint' do
    let(:store_endpoints) do
      {
        'identity' => 'https://config-identity.example.com',
        'compute' => 'https://config-compute.example.com'
      }
    end

    context 'when endpoint exists in configuration stores' do
      it 'returns endpoint from stores' do
        allow(mock_reader).to receive(:get_all_endpoints).with(config_name).and_return(store_endpoints)

        result = subject.get_endpoint('identity')

        expect(result).to eq('https://config-identity.example.com')
      end

      it 'prefers store endpoints over local endpoints' do
        allow(mock_reader).to receive(:get_all_endpoints).with(config_name).and_return(store_endpoints)
        allow(subject).to receive(:get_local_endpoints).and_return({ 'identity' => 'https://local.example.com' })

        result = subject.get_endpoint('identity')

        expect(result).to eq('https://config-identity.example.com')
      end
    end

    context 'when endpoint does not exist in configuration stores' do
      it 'returns endpoint from local endpoints' do
        allow(mock_reader).to receive(:get_all_endpoints).with(config_name).and_return({})
        allow(subject).to receive(:get_local_endpoints).and_return({ 'identity' => 'https://local.example.com' })

        result = subject.get_endpoint('identity')

        expect(result).to eq('https://local.example.com')
      end

      it 'returns nil when endpoint not found anywhere' do
        allow(mock_reader).to receive(:get_all_endpoints).with(config_name).and_return({})
        allow(subject).to receive(:get_local_endpoints).and_return({})

        result = subject.get_endpoint('nonexistent')

        expect(result).to be_nil
      end
    end
  end

  describe '#get_all_endpoints' do
    let(:store_endpoints) { { 'identity' => 'https://store.example.com' } }
    let(:local_endpoints) { { 'compute' => 'https://local.example.com', 'identity' => 'https://local-identity.example.com' } }

    it 'merges local and store endpoints with store having priority' do
      allow(mock_reader).to receive(:get_all_endpoints).with(config_name).and_return(store_endpoints)
      allow(subject).to receive(:get_local_endpoints).and_return(local_endpoints)

      result = subject.get_all_endpoints

      expect(result).to eq({
        'compute' => 'https://local.example.com',        # from local
        'identity' => 'https://store.example.com'        # store overrides local
      })
    end

    it 'returns only store endpoints when no local endpoints' do
      allow(mock_reader).to receive(:get_all_endpoints).with(config_name).and_return(store_endpoints)
      allow(subject).to receive(:get_local_endpoints).and_return({})

      result = subject.get_all_endpoints

      expect(result).to eq(store_endpoints)
    end

    it 'returns only local endpoints when no store endpoints' do
      allow(mock_reader).to receive(:get_all_endpoints).with(config_name).and_return({})
      allow(subject).to receive(:get_local_endpoints).and_return(local_endpoints)

      result = subject.get_all_endpoints

      expect(result).to eq(local_endpoints)
    end
  end

  describe '#endpoint_exists?' do
    it 'returns true when endpoint exists' do
      allow(subject).to receive(:get_endpoint).with('identity').and_return('https://example.com')

      result = subject.endpoint_exists?('identity')

      expect(result).to be true
    end

    it 'returns false when endpoint does not exist' do
      allow(subject).to receive(:get_endpoint).with('nonexistent').and_return(nil)

      result = subject.endpoint_exists?('nonexistent')

      expect(result).to be false
    end
  end

  describe '#get_local_endpoints (private)' do
    context 'with zero configuration' do
      let(:zero_lookup) { described_class.new(mock_reader, 'zero') }

      it 'returns zero endpoints for zero config' do
        zero_endpoints = { 'identity' => 'https://zero.example.com' }
        allow(zero_lookup).to receive(:get_zero_endpoints).and_return(zero_endpoints)

        result = zero_lookup.send(:get_local_endpoints)

        expect(result).to eq(zero_endpoints)
      end

      it 'handles case-insensitive zero config name' do
        zero_lookup = described_class.new(mock_reader, 'ZERO')
        zero_endpoints = { 'identity' => 'https://zero.example.com' }
        allow(zero_lookup).to receive(:get_zero_endpoints).and_return(zero_endpoints)

        result = zero_lookup.send(:get_local_endpoints)

        expect(result).to eq(zero_endpoints)
      end
    end

    context 'with non-zero configuration' do
      it 'returns empty hash for non-zero configs' do
        result = subject.send(:get_local_endpoints)

        expect(result).to eq({})
      end
    end
  end

  describe '#get_zero_endpoints (private)' do
    let(:zero_lookup) { described_class.new(mock_reader, 'zero') }
    let(:mock_provider_info) { double('LocalIdentityProviderInfo') }

    before do
      allow(Eryph::ClientRuntime::LocalIdentityProviderInfo).to receive(:new)
        .with(mock_environment, 'zero')
        .and_return(mock_provider_info)
    end

    context 'when identity provider is running' do
      let(:provider_endpoints) do
        {
          'identity' => URI.parse('https://localhost:8080/identity'),
          'compute' => URI.parse('https://localhost:8080/compute')
        }
      end

      it 'returns endpoints from running provider' do
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:endpoints).and_return(provider_endpoints)

        result = zero_lookup.send(:get_zero_endpoints)

        expect(result).to eq({
          'identity' => 'https://localhost:8080/identity',
          'compute' => 'https://localhost:8080/compute'
        })
      end

      it 'derives compute endpoint when only identity exists' do
        identity_only = { 'identity' => URI.parse('https://localhost:8080/identity') }
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:endpoints).and_return(identity_only)

        result = zero_lookup.send(:get_zero_endpoints)

        expect(result).to eq({
          'identity' => 'https://localhost:8080/identity',
          'compute' => 'https://localhost:8080/compute'
        })
      end

      it 'includes other endpoints as-is' do
        extended_endpoints = {
          'identity' => URI.parse('https://localhost:8080/identity'),
          'management' => URI.parse('https://localhost:8080/management')
        }
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:endpoints).and_return(extended_endpoints)

        result = zero_lookup.send(:get_zero_endpoints)

        expect(result).to eq({
          'identity' => 'https://localhost:8080/identity',
          'compute' => 'https://localhost:8080/compute',
          'management' => 'https://localhost:8080/management'
        })
      end

      it 'handles case-insensitive endpoint names' do
        mixed_case = {
          'IDENTITY' => URI.parse('https://localhost:8080/identity'),
          'COMPUTE' => URI.parse('https://localhost:8080/compute')
        }
        allow(mock_provider_info).to receive(:running?).and_return(true)
        allow(mock_provider_info).to receive(:endpoints).and_return(mixed_case)

        result = zero_lookup.send(:get_zero_endpoints)

        expect(result).to eq({
          'identity' => 'https://localhost:8080/identity',
          'compute' => 'https://localhost:8080/compute'
        })
      end
    end

    context 'when identity provider is not running' do
      it 'returns fallback endpoints' do
        allow(mock_provider_info).to receive(:running?).and_return(false)
        fallback_endpoints = { 'identity' => 'https://localhost:8080', 'compute' => 'https://localhost:8080/compute' }
        allow(zero_lookup).to receive(:fallback_zero_endpoints).and_return(fallback_endpoints)

        result = zero_lookup.send(:get_zero_endpoints)

        expect(result).to eq(fallback_endpoints)
      end
    end
  end

  describe '#fallback_zero_endpoints (private)' do
    let(:zero_lookup) { described_class.new(mock_reader, 'zero') }

    context 'when a candidate endpoint responds' do
      it 'returns endpoints for first working candidate' do
        allow(zero_lookup).to receive(:test_zero_endpoint).with('https://localhost:8080').and_return(true)

        result = zero_lookup.send(:fallback_zero_endpoints)

        expect(result).to eq({
          'identity' => 'https://localhost:8080',
          'compute' => 'https://localhost:8080/compute'
        })
      end

      it 'tries candidates in order until one works' do
        allow(zero_lookup).to receive(:test_zero_endpoint).with('https://localhost:8080').and_return(false)
        allow(zero_lookup).to receive(:test_zero_endpoint).with('https://127.0.0.1:8080').and_return(true)

        result = zero_lookup.send(:fallback_zero_endpoints)

        expect(result).to eq({
          'identity' => 'https://127.0.0.1:8080',
          'compute' => 'https://127.0.0.1:8080/compute'
        })
      end
    end

    context 'when no candidate endpoints respond' do
      it 'returns empty endpoints hash' do
        allow(zero_lookup).to receive(:test_zero_endpoint).and_return(false)

        result = zero_lookup.send(:fallback_zero_endpoints)

        expect(result).to eq({})
      end
    end
  end

  describe '#test_zero_endpoint (private)' do
    let(:zero_lookup) { described_class.new(mock_reader, 'zero') }

    it 'returns true for valid HTTPS URL with port' do
      result = zero_lookup.send(:test_zero_endpoint, 'https://localhost:8080')

      expect(result).to be true
    end

    it 'returns true for valid HTTP URL with port' do
      result = zero_lookup.send(:test_zero_endpoint, 'http://127.0.0.1:8080')

      expect(result).to be true
    end

    it 'returns true for valid URL with host and port' do
      result = zero_lookup.send(:test_zero_endpoint, 'https://example.com:443')

      expect(result).to be true
    end

    it 'returns false for URL without port' do
      result = zero_lookup.send(:test_zero_endpoint, 'https://localhost')

      expect(result).to be false
    end

    it 'returns false for URL without scheme' do
      result = zero_lookup.send(:test_zero_endpoint, 'localhost:8080')

      expect(result).to be false
    end

    it 'returns false for URL without host' do
      result = zero_lookup.send(:test_zero_endpoint, 'https://:8080')

      expect(result).to be false
    end

    it 'returns false for invalid URL' do
      result = zero_lookup.send(:test_zero_endpoint, 'not-a-url')

      expect(result).to be false
    end

    it 'handles URI parse errors gracefully' do
      allow(URI).to receive(:parse).and_raise(URI::InvalidURIError)

      result = zero_lookup.send(:test_zero_endpoint, 'malformed-url')

      expect(result).to be false
    end
  end
end