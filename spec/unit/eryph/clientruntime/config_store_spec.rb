require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::ConfigStore do
  let(:base_path) { '/test/path' }
  let(:config_name) { 'test' }
  let(:environment) { double('Environment') }
  let(:config_store) { described_class.new(base_path, config_name, environment) }
  
  describe '#initialize' do
    it 'creates a config store with base path and config name' do
      expect(config_store.base_path).to eq(base_path)
      expect(config_store.config_name).to eq(config_name)
      expect(config_store.environment).to eq(environment)
    end
  end
  
  describe '#exists?' do
    it 'returns true when config file exists' do
      allow(environment).to receive(:file_exists?).and_return(true)
      expect(config_store.exists?).to be true
    end
    
    it 'returns false when config file does not exist' do
      allow(environment).to receive(:file_exists?).and_return(false)
      expect(config_store.exists?).to be false
    end

    it 'checks the correct config file path' do
      expected_path = File.join(base_path, '.eryph', 'test.config')
      expect(environment).to receive(:file_exists?).with(expected_path)
      config_store.exists?
    end
  end
  
  describe '#configuration' do
    it 'returns empty hash when config does not exist' do
      allow(config_store).to receive(:exists?).and_return(false)
      expect(config_store.configuration).to eq({})
    end

    it 'parses JSON configuration when file exists' do
      config_content = { 'endpoints' => { 'identity' => 'https://example.com' } }.to_json
      allow(config_store).to receive(:exists?).and_return(true)
      allow(environment).to receive(:read_file).and_return(config_content)

      result = config_store.configuration

      expect(result).to eq({ 'endpoints' => { 'identity' => 'https://example.com' } })
    end

    it 'raises ConfigurationError for invalid JSON' do
      allow(config_store).to receive(:exists?).and_return(true)
      allow(environment).to receive(:read_file).and_return('invalid json {')

      expect { config_store.configuration }.to raise_error(
        Eryph::ClientRuntime::ConfigurationError, 
        /Invalid JSON in configuration file/
      )
    end

    it 'raises ConfigurationError for IO errors' do
      allow(config_store).to receive(:exists?).and_return(true)
      allow(environment).to receive(:read_file).and_raise(IOError.new('File read error'))

      expect { config_store.configuration }.to raise_error(
        Eryph::ClientRuntime::ConfigurationError, 
        /Cannot read configuration file/
      )
    end
  end

  describe '#endpoints' do
    it 'returns endpoints from configuration' do
      config_data = { 'endpoints' => { 'identity' => 'https://identity.example.com' } }
      allow(config_store).to receive(:configuration).and_return(config_data)

      endpoints = config_store.endpoints

      expect(endpoints).to eq({ 'identity' => 'https://identity.example.com' })
    end

    it 'returns empty hash when no endpoints configured' do
      allow(config_store).to receive(:configuration).and_return({})

      endpoints = config_store.endpoints

      expect(endpoints).to eq({})
    end

    it 'returns empty hash when endpoints is nil' do
      config_data = { 'endpoints' => nil }
      allow(config_store).to receive(:configuration).and_return(config_data)

      endpoints = config_store.endpoints

      expect(endpoints).to eq({})
    end
  end

  describe '#clients' do
    let(:clients_data) do
      [
        { 'id' => 'client1', 'name' => 'Client 1' },
        { 'id' => 'client2', 'name' => 'Client 2' }
      ]
    end

    it 'returns clients from configuration' do
      config_data = { 'clients' => clients_data }
      allow(config_store).to receive(:configuration).and_return(config_data)

      clients = config_store.clients

      expect(clients).to eq(clients_data)
    end

    it 'returns empty array when no clients configured' do
      allow(config_store).to receive(:configuration).and_return({})

      clients = config_store.clients

      expect(clients).to eq([])
    end

    it 'returns empty array when clients is nil' do
      config_data = { 'clients' => nil }
      allow(config_store).to receive(:configuration).and_return(config_data)

      clients = config_store.clients

      expect(clients).to eq([])
    end
  end

  describe '#default_client_id' do
    it 'returns default client ID from configuration' do
      config_data = { 'defaultClient' => 'client1' }
      allow(config_store).to receive(:configuration).and_return(config_data)

      default_id = config_store.default_client_id

      expect(default_id).to eq('client1')
    end

    it 'returns nil when no default client configured' do
      allow(config_store).to receive(:configuration).and_return({})

      default_id = config_store.default_client_id

      expect(default_id).to be_nil
    end
  end

  describe '#get_client' do
    let(:clients_data) do
      [
        { 'id' => 'client1', 'name' => 'Client 1' },
        { 'id' => 'client2', 'name' => 'Client 2' }
      ]
    end

    it 'returns client with matching ID' do
      allow(config_store).to receive(:clients).and_return(clients_data)

      client = config_store.get_client('client2')

      expect(client).to eq({ 'id' => 'client2', 'name' => 'Client 2' })
    end

    it 'returns nil when client not found' do
      allow(config_store).to receive(:clients).and_return(clients_data)

      client = config_store.get_client('nonexistent')

      expect(client).to be_nil
    end

    it 'returns nil when no clients configured' do
      allow(config_store).to receive(:clients).and_return([])

      client = config_store.get_client('client1')

      expect(client).to be_nil
    end
  end

  describe '#get_private_key' do
    let(:private_key_content) { 'private key content' }
    let(:key_path) { File.join(base_path, '.eryph', 'private', 'client1.key') }

    it 'returns private key when file exists' do
      allow(environment).to receive(:file_exists?).with(key_path).and_return(true)
      allow(environment).to receive(:read_file).with(key_path).and_return(private_key_content)

      private_key = config_store.get_private_key('client1')

      expect(private_key).to eq(private_key_content)
    end

    it 'returns nil when private key file does not exist' do
      allow(environment).to receive(:file_exists?).with(key_path).and_return(false)

      private_key = config_store.get_private_key('client1')

      expect(private_key).to be_nil
    end

    it 'returns nil when file read fails' do
      allow(environment).to receive(:file_exists?).with(key_path).and_return(true)
      allow(environment).to receive(:read_file).with(key_path).and_raise(IOError.new('Read error'))

      private_key = config_store.get_private_key('client1')

      expect(private_key).to be_nil
    end
  end

  describe '#store_client' do
    let(:client_config) { { 'id' => 'new-client', 'name' => 'New Client' } }
    let(:existing_config) { { 'clients' => [] } }

    before do
      allow(config_store).to receive(:configuration).and_return(existing_config.dup)
      allow(config_store).to receive(:save_configuration)
    end

    it 'adds new client to configuration' do
      expected_config = {
        'clients' => [client_config],
        'defaultClient' => 'new-client'
      }

      config_store.store_client(client_config)

      expect(config_store).to have_received(:save_configuration).with(expected_config)
    end

    it 'replaces existing client with same ID' do
      existing_client = { 'id' => 'new-client', 'name' => 'Old Name' }
      existing_config['clients'] = [existing_client]
      expected_config = {
        'clients' => [client_config],
        'defaultClient' => 'new-client'
      }

      config_store.store_client(client_config)

      expect(config_store).to have_received(:save_configuration).with(expected_config)
    end

    it 'does not overwrite existing default client' do
      existing_config_with_default = { 'clients' => [], 'defaultClient' => 'existing-default' }
      allow(config_store).to receive(:configuration).and_return(existing_config_with_default.dup)
      expected_config = {
        'clients' => [client_config],
        'defaultClient' => 'existing-default'
      }

      config_store.store_client(client_config)

      expect(config_store).to have_received(:save_configuration).with(expected_config)
    end

    it 'initializes clients array when nil' do
      allow(config_store).to receive(:configuration).and_return({})
      expected_config = {
        'clients' => [client_config],
        'defaultClient' => 'new-client'
      }

      config_store.store_client(client_config)

      expect(config_store).to have_received(:save_configuration).with(expected_config)
    end
  end

  describe '#store_private_key' do
    let(:client_id) { 'client1' }
    let(:private_key) { 'private key content' }
    let(:key_path) { File.join(base_path, '.eryph', 'private', 'client1.key') }
    let(:key_dir) { File.join(base_path, '.eryph', 'private') }

    it 'stores private key to correct path' do
      allow(environment).to receive(:ensure_directory)
      allow(environment).to receive(:write_file)
      allow(environment).to receive(:windows?).and_return(true)

      config_store.store_private_key(client_id, private_key)

      expect(environment).to have_received(:ensure_directory).with(key_dir)
      expect(environment).to have_received(:write_file).with(key_path, private_key)
    end

    it 'sets restrictive permissions on Unix systems' do
      allow(environment).to receive(:ensure_directory)
      allow(environment).to receive(:write_file)
      allow(environment).to receive(:windows?).and_return(false)
      allow(File).to receive(:chmod)

      config_store.store_private_key(client_id, private_key)

      expect(File).to have_received(:chmod).with(0600, key_path)
    end

    it 'does not set permissions on Windows' do
      allow(environment).to receive(:ensure_directory)
      allow(environment).to receive(:write_file)
      allow(environment).to receive(:windows?).and_return(true)
      allow(File).to receive(:chmod)

      config_store.store_private_key(client_id, private_key)

      expect(File).not_to have_received(:chmod)
    end

    it 'raises ConfigurationError when write fails' do
      allow(environment).to receive(:ensure_directory)
      allow(environment).to receive(:write_file).and_raise(IOError.new('Write error'))

      expect { config_store.store_private_key(client_id, private_key) }.to raise_error(
        Eryph::ClientRuntime::ConfigurationError,
        /Cannot store private key/
      )
    end
  end

  describe '#store_endpoint' do
    let(:endpoint_name) { 'identity' }
    let(:endpoint_url) { 'https://identity.example.com' }
    let(:existing_config) { {} }

    before do
      allow(config_store).to receive(:configuration).and_return(existing_config.dup)
      allow(config_store).to receive(:save_configuration)
    end

    it 'adds endpoint to configuration' do
      expected_config = {
        'endpoints' => { endpoint_name => endpoint_url }
      }

      config_store.store_endpoint(endpoint_name, endpoint_url)

      expect(config_store).to have_received(:save_configuration).with(expected_config)
    end

    it 'replaces existing endpoint with same name' do
      existing_config['endpoints'] = { endpoint_name => 'old-url' }
      expected_config = {
        'endpoints' => { endpoint_name => endpoint_url }
      }

      config_store.store_endpoint(endpoint_name, endpoint_url)

      expect(config_store).to have_received(:save_configuration).with(expected_config)
    end

    it 'initializes endpoints hash when nil' do
      expected_config = {
        'endpoints' => { endpoint_name => endpoint_url }
      }

      config_store.store_endpoint(endpoint_name, endpoint_url)

      expect(config_store).to have_received(:save_configuration).with(expected_config)
    end
  end

  describe 'path methods' do
    describe '#store_path' do
      it 'returns correct store path' do
        expected_path = File.join(base_path, '.eryph')
        expect(config_store.store_path).to eq(expected_path)
      end
    end

    describe '#config_file_path' do
      it 'returns correct config file path' do
        expected_path = File.join(base_path, '.eryph', 'test.config')
        expect(config_store.config_file_path).to eq(expected_path)
      end
    end

    describe '#private_key_directory' do
      it 'returns correct private key directory path' do
        expected_path = File.join(base_path, '.eryph', 'private')
        expect(config_store.private_key_directory).to eq(expected_path)
      end
    end

    describe '#private_key_path' do
      it 'returns correct private key file path' do
        expected_path = File.join(base_path, '.eryph', 'private', 'client1.key')
        expect(config_store.private_key_path('client1')).to eq(expected_path)
      end
    end
  end

  describe '#save_configuration (private)' do
    let(:config_data) { { 'test' => 'data' } }
    let(:config_path) { File.join(base_path, '.eryph', 'test.config') }
    let(:store_dir) { File.join(base_path, '.eryph') }

    it 'saves configuration as pretty JSON' do
      allow(environment).to receive(:ensure_directory)
      allow(environment).to receive(:write_file)
      expected_json = JSON.pretty_generate(config_data)

      config_store.send(:save_configuration, config_data)

      expect(environment).to have_received(:ensure_directory).with(store_dir)
      expect(environment).to have_received(:write_file).with(config_path, expected_json)
    end

    it 'raises ConfigurationError when save fails' do
      allow(environment).to receive(:ensure_directory)
      allow(environment).to receive(:write_file).and_raise(IOError.new('Write error'))

      expect { config_store.send(:save_configuration, config_data) }.to raise_error(
        Eryph::ClientRuntime::ConfigurationError,
        /Cannot save configuration/
      )
    end
  end
end