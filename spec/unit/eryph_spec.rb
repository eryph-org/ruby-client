require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'json'

RSpec.describe Eryph do
  describe '.compute_client' do
    context 'with over-mocked dependencies (legacy - should be refactored)' do
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

    context 'with minimal mocking (tests real code paths)' do
      let(:mock_environment) { double('Environment') }
      let(:temp_dir) { Dir.mktmpdir('eryph-test') }
      let(:config_dir) { File.join(temp_dir, '.eryph') }
      
      before do
        # Only mock Environment for OS behavior
        allow(Eryph::ClientRuntime::Environment).to receive(:new).and_return(mock_environment)
        allow(mock_environment).to receive(:windows?).and_return(true)
        allow(mock_environment).to receive(:linux?).and_return(false)
        allow(mock_environment).to receive(:admin_user?).and_return(false)
        
        # Mock file system paths but use real config logic
        allow(mock_environment).to receive(:get_config_path).with(Eryph::ClientRuntime::Environment::ConfigStoreLocation::USER).and_return(config_dir)
        allow(mock_environment).to receive(:get_config_path).with(Eryph::ClientRuntime::Environment::ConfigStoreLocation::SYSTEM).and_return(File.join(temp_dir, 'system'))
        allow(mock_environment).to receive(:get_config_path).with(Eryph::ClientRuntime::Environment::ConfigStoreLocation::CURRENT_DIRECTORY).and_return(File.join(temp_dir, 'current'))
        
        # Mock file operations but delegate to real file system
        allow(mock_environment).to receive(:file_exists?) { |path| File.exist?(path) }
        allow(mock_environment).to receive(:read_config_file) { |path| File.exist?(path) ? File.read(path) : nil }
        
        # Create minimal config structure
        FileUtils.mkdir_p(config_dir)
      end
      
      after do
        FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
      end

      it 'does not crash on nil.downcase during automatic discovery' do
        expect {
          described_class.compute_client(nil)
        }.not_to raise_error(NoMethodError)
      end
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