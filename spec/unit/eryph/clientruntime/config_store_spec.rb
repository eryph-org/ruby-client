require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::ConfigStore do
  # Test with real business logic - Environment is the only mocked boundary
  describe 'real business logic tests' do
    let(:test_environment) { TestEnvironment.new }
    let(:base_path) { '/test/user' }
    let(:config_name) { 'test' }
    let(:store) { described_class.new(base_path, config_name, test_environment) }

    describe '#initialize' do
      it 'stores configuration parameters' do
        expect(store.base_path).to eq(base_path)
        expect(store.config_name).to eq(config_name)
        expect(store.environment).to eq(test_environment)
      end
    end

    describe '#exists?' do
      it 'returns true when config file exists' do
        # Setup config file in test environment
        config_path = File.join(base_path, '.eryph', 'test.config')
        test_environment.add_config_file(config_path, { 'test' => 'data' })
        
        expect(store.exists?).to be true
      end

      it 'returns false when config file does not exist' do
        expect(store.exists?).to be false
      end
    end

    describe '#configuration' do
      it 'returns parsed JSON configuration when file exists' do
        config_data = {
          'clients' => [{ 'id' => 'test-client', 'name' => 'Test Client' }],
          'endpoints' => { 'identity' => 'https://test.local/identity' }
        }
        config_path = File.join(base_path, '.eryph', 'test.config')
        test_environment.add_config_file(config_path, config_data)

        result = store.configuration
        
        expect(result).to eq(config_data)
      end

      it 'returns empty hash when file does not exist' do
        result = store.configuration
        
        expect(result).to eq({})
      end

      it 'raises ConfigurationError for invalid JSON' do
        config_path = File.join(base_path, '.eryph', 'test.config')
        test_environment.add_raw_config_file(config_path, 'invalid json {')

        expect {
          store.configuration
        }.to raise_error(
          Eryph::ClientRuntime::ConfigurationError,
          /Invalid JSON in configuration file/
        )
      end
    end

    describe '#clients' do
      it 'returns clients array from configuration' do
        clients_data = [
          { 'id' => 'client-1', 'name' => 'First Client' },
          { 'id' => 'client-2', 'name' => 'Second Client' }
        ]
        config_path = File.join(base_path, '.eryph', 'test.config')
        test_environment.add_config_file(config_path, { 'clients' => clients_data })

        result = store.clients
        
        expect(result).to eq(clients_data)
      end

      it 'returns empty array when no clients configured' do
        config_path = File.join(base_path, '.eryph', 'test.config')
        test_environment.add_config_file(config_path, {})

        result = store.clients
        
        expect(result).to eq([])
      end

      it 'returns empty array when store does not exist' do
        result = store.clients
        
        expect(result).to eq([])
      end
    end

    describe '#get_client' do
      before do
        clients_data = [
          { 'id' => 'client-1', 'name' => 'First Client' },
          { 'id' => 'client-2', 'name' => 'Second Client' }
        ]
        config_path = File.join(base_path, '.eryph', 'test.config')
        test_environment.add_config_file(config_path, { 'clients' => clients_data })
      end

      it 'finds client by ID' do
        client = store.get_client('client-1')
        
        expect(client).to include('id' => 'client-1', 'name' => 'First Client')
      end

      it 'returns nil for non-existent client ID' do
        client = store.get_client('missing')
        
        expect(client).to be_nil
      end
    end

    describe '#default_client' do
      context 'with explicit defaultClientId' do
        before do
          clients_data = [
            { 'id' => 'client-1', 'name' => 'First Client' },
            { 'id' => 'client-2', 'name' => 'Second Client' }
          ]
          config_data = {
            'clients' => clients_data,
            'defaultClientId' => 'client-2'
          }
          config_path = File.join(base_path, '.eryph', 'test.config')
          test_environment.add_config_file(config_path, config_data)
        end

        it 'returns client specified by defaultClientId' do
          client = store.default_client
          
          expect(client).to include('id' => 'client-2', 'name' => 'Second Client')
        end
      end

      context 'without explicit defaultClientId' do
        before do
          clients_data = [
            { 'id' => 'client-1', 'name' => 'First Client' },
            { 'id' => 'client-2', 'name' => 'Second Client' }
          ]
          config_path = File.join(base_path, '.eryph', 'test.config')
          test_environment.add_config_file(config_path, { 'clients' => clients_data })
        end

        it 'returns first client when no defaultClientId specified' do
          client = store.default_client
          
          expect(client).to include('id' => 'client-1', 'name' => 'First Client')
        end
      end

      it 'returns nil when no clients exist' do
        config_path = File.join(base_path, '.eryph', 'test.config')
        test_environment.add_config_file(config_path, {})

        client = store.default_client
        
        expect(client).to be_nil
      end
    end

    describe '#get_client_private_key' do
      let(:test_client) { { 'id' => 'test-client', 'name' => 'Test Client' } }
      let(:test_key) { OpenSSL::PKey::RSA.generate(2048).to_pem }

      it 'returns private key for client' do
        # Setup client and private key
        key_path = File.join(base_path, '.eryph', 'private', 'test-client.key')
        test_environment.add_private_key_file(key_path, test_key)

        result = store.get_client_private_key(test_client)
        
        expect(result).to eq(test_key)
      end

      it 'returns nil when private key file does not exist' do
        result = store.get_client_private_key(test_client)
        
        expect(result).to be_nil
      end

      it 'handles client data with _store attribute' do
        # Client data sometimes includes _store reference
        client_with_store = test_client.merge('_store' => store)
        
        key_path = File.join(base_path, '.eryph', 'private', 'test-client.key')
        test_environment.add_private_key_file(key_path, test_key)

        result = store.get_client_private_key(client_with_store)
        
        expect(result).to eq(test_key)
      end
    end

    describe 'path methods' do
      it 'generates correct config file path' do
        expected_path = File.join(base_path, '.eryph', 'test.config')
        
        expect(store.send(:config_file_path)).to eq(expected_path)
      end

      it 'generates correct private key path' do
        expected_path = File.join(base_path, '.eryph', 'private', 'client-id.key')
        
        expect(store.send(:private_key_path, 'client-id')).to eq(expected_path)
      end
    end
  end

  # Special case tests - mock only complex external dependencies
  describe 'error handling edge cases' do
    let(:mock_environment) { double('Environment') }
    let(:store) { described_class.new('/test/path', 'test', mock_environment) }

    it 'handles file read errors gracefully' do
      allow(mock_environment).to receive(:file_exists?).and_return(true)
      allow(mock_environment).to receive(:read_file).and_raise(IOError, 'Permission denied')

      expect {
        store.configuration
      }.to raise_error(Eryph::ClientRuntime::ConfigurationError, /Cannot read configuration file/)
    end
  end
end