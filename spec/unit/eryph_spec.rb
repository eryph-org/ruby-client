require 'spec_helper'

RSpec.describe Eryph do
  describe '.compute_client' do
    let(:mock_environment) { double('Environment') }
    let(:mock_reader) { double('ConfigStoresReader') }
    let(:credentials_lookup) { double('CredentialsLookup') }
    let(:credentials) { build(:credentials) }
    
    before do
      allow(Eryph::ClientRuntime::Environment).to receive(:new).and_return(mock_environment)
      allow(Eryph::ClientRuntime::ConfigStoresReader).to receive(:new).and_return(mock_reader)
      allow(Eryph::ClientRuntime::ClientCredentialsLookup).to receive(:new).and_return(credentials_lookup)
      allow(Eryph::ClientRuntime::EndpointLookup).to receive(:new).and_return(double('EndpointLookup', get_endpoint: 'https://test.eryph.local/compute'))
      allow(credentials_lookup).to receive(:find_credentials).and_return(credentials)
    end
    
    it 'creates compute client with automatic discovery' do
      client = described_class.compute_client
      expect(client).to be_a(Eryph::Compute::Client)
    end
    
    it 'creates compute client with specific config' do
      client = described_class.compute_client('test')
      expect(client).to be_a(Eryph::Compute::Client)
    end
    
    it 'passes through options' do
      expect(Eryph::Compute::Client).to receive(:new).with('test', client_id: 'my-client', environment: nil, logger: nil, scopes: nil, ssl_config: {})
      described_class.compute_client('test', client_id: 'my-client')
    end
  end
  
  describe '.credentials_available?' do
    it 'delegates to ClientRuntime' do
      expect(Eryph::ClientRuntime).to receive(:credentials_available?).with(config_name: nil).and_return(true)
      result = described_class.credentials_available?
      expect(result).to be true
    end
    
    it 'passes config_name parameter' do
      expect(Eryph::ClientRuntime).to receive(:credentials_available?).with(config_name: 'test').and_return(false)
      result = described_class.credentials_available?('test')
      expect(result).to be false
    end
  end
end