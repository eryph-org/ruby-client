require 'spec_helper'
require 'set'

RSpec.describe Eryph::ClientRuntime::ConfigStoresReader do
  let(:mock_environment) { double('Environment') }
  let(:config_name) { 'test' }
  
  subject { described_class.new(mock_environment) }

  describe '#initialize' do
    it 'stores the environment dependency' do
      reader = described_class.new(mock_environment)
      expect(reader.environment).to eq(mock_environment)
    end
  end

  describe '#get_stores' do
    let(:current_path) { '/current/path' }
    let(:user_path) { '/user/path' }
    let(:system_path) { '/system/path' }

    before do
      allow(mock_environment).to receive(:get_config_path)
        .with(Eryph::ClientRuntime::Environment::ConfigStoreLocation::CURRENT_DIRECTORY)
        .and_return(current_path)
      allow(mock_environment).to receive(:get_config_path)
        .with(Eryph::ClientRuntime::Environment::ConfigStoreLocation::USER)
        .and_return(user_path)
      allow(mock_environment).to receive(:get_config_path)
        .with(Eryph::ClientRuntime::Environment::ConfigStoreLocation::SYSTEM)
        .and_return(system_path)
    end

    it 'returns stores in priority order (current, user, system)' do
      stores = subject.get_stores(config_name)

      expect(stores.size).to eq(3)
      expect(stores[0].base_path).to eq(current_path)
      expect(stores[1].base_path).to eq(user_path)
      expect(stores[2].base_path).to eq(system_path)
      stores.each { |store| expect(store.config_name).to eq(config_name) }
    end

    it 'passes environment to each store' do
      stores = subject.get_stores(config_name)
      stores.each { |store| expect(store.environment).to eq(mock_environment) }
    end
  end

  describe '#get_existing_stores' do
    let(:mock_store1) { double('ConfigStore1', exists?: true) }
    let(:mock_store2) { double('ConfigStore2', exists?: false) }
    let(:mock_store3) { double('ConfigStore3', exists?: true) }

    it 'returns only stores that exist' do
      allow(subject).to receive(:get_stores).and_return([mock_store1, mock_store2, mock_store3])

      existing_stores = subject.get_existing_stores(config_name)

      expect(existing_stores).to eq([mock_store1, mock_store3])
    end

    it 'returns empty array when no stores exist' do
      allow(subject).to receive(:get_stores).and_return([mock_store2])

      existing_stores = subject.get_existing_stores(config_name)

      expect(existing_stores).to be_empty
    end
  end

  describe '#get_merged_configuration' do
    let(:system_config) { { 'endpoints' => { 'identity' => 'system-url' }, 'global' => 'system' } }
    let(:user_config) { { 'endpoints' => { 'compute' => 'user-url' }, 'user' => 'override' } }
    let(:current_config) { { 'endpoints' => { 'identity' => 'current-url' }, 'current' => 'value' } }

    let(:system_store) { double('SystemStore', configuration: system_config) }
    let(:user_store) { double('UserStore', configuration: user_config) }
    let(:current_store) { double('CurrentStore', configuration: current_config) }

    it 'merges configurations with proper priority (current > user > system)' do
      allow(subject).to receive(:get_existing_stores).and_return([current_store, user_store, system_store])

      merged = subject.get_merged_configuration(config_name)

      expect(merged).to eq({
        'endpoints' => {
          'identity' => 'current-url',  # current overrides system
          'compute' => 'user-url'       # user adds new endpoint
        },
        'global' => 'system',           # system provides base value
        'user' => 'override',           # user adds value
        'current' => 'value'            # current adds value
      })
    end

    it 'handles nested hash merging correctly' do
      system_config = { 'nested' => { 'a' => 'system', 'b' => 'system' } }
      user_config = { 'nested' => { 'b' => 'user', 'c' => 'user' } }
      
      system_store = double('SystemStore', configuration: system_config)
      user_store = double('UserStore', configuration: user_config)

      allow(subject).to receive(:get_existing_stores).and_return([user_store, system_store])

      merged = subject.get_merged_configuration(config_name)

      expect(merged['nested']).to eq({
        'a' => 'system',  # from system
        'b' => 'user',    # user overrides system
        'c' => 'user'     # from user
      })
    end

    it 'returns empty hash when no stores exist' do
      allow(subject).to receive(:get_existing_stores).and_return([])

      merged = subject.get_merged_configuration(config_name)

      expect(merged).to eq({})
    end
  end

  describe '#get_all_endpoints' do
    let(:merged_config) do
      { 
        'endpoints' => { 
          'identity' => 'https://identity.example.com',
          'compute' => 'https://compute.example.com'
        }
      }
    end

    it 'returns endpoints from merged configuration' do
      allow(subject).to receive(:get_merged_configuration).and_return(merged_config)

      endpoints = subject.get_all_endpoints(config_name)

      expect(endpoints).to eq({
        'identity' => 'https://identity.example.com',
        'compute' => 'https://compute.example.com'
      })
    end

    it 'returns empty hash when no endpoints configured' do
      allow(subject).to receive(:get_merged_configuration).and_return({})

      endpoints = subject.get_all_endpoints(config_name)

      expect(endpoints).to eq({})
    end

    it 'returns empty hash when endpoints key is nil' do
      allow(subject).to receive(:get_merged_configuration).and_return({ 'other' => 'value' })

      endpoints = subject.get_all_endpoints(config_name)

      expect(endpoints).to eq({})
    end
  end

  describe '#get_all_clients' do
    let(:client1) { { 'id' => 'client1', 'name' => 'Client 1' } }
    let(:client2) { { 'id' => 'client2', 'name' => 'Client 2' } }
    let(:client3) { { 'id' => 'client1', 'name' => 'Client 1 Override' } }  # Duplicate ID

    let(:store1) { double('Store1', clients: [client1, client2]) }
    let(:store2) { double('Store2', clients: [client3]) }

    it 'returns all clients with store references' do
      allow(subject).to receive(:get_existing_stores).and_return([store1, store2])

      clients = subject.get_all_clients(config_name)

      expect(clients.size).to eq(2)
      
      # First client should be from store1 (higher priority)
      first_client = clients.find { |c| c['id'] == 'client1' }
      expect(first_client['name']).to eq('Client 1')
      expect(first_client['_store']).to eq(store1)
      
      # Second client should be from store1
      second_client = clients.find { |c| c['id'] == 'client2' }
      expect(second_client['name']).to eq('Client 2')
      expect(second_client['_store']).to eq(store1)
    end

    it 'removes duplicates keeping first occurrence (highest priority)' do
      allow(subject).to receive(:get_existing_stores).and_return([store1, store2])

      clients = subject.get_all_clients(config_name)

      client1_instances = clients.select { |c| c['id'] == 'client1' }
      expect(client1_instances.size).to eq(1)
      expect(client1_instances.first['name']).to eq('Client 1')  # From store1, not store2
    end

    it 'handles empty clients arrays' do
      empty_store = double('EmptyStore', clients: [])
      allow(subject).to receive(:get_existing_stores).and_return([empty_store])

      clients = subject.get_all_clients(config_name)

      expect(clients).to be_empty
    end

    it 'handles stores with nil clients' do
      nil_store = double('NilStore', clients: nil)
      allow(subject).to receive(:get_existing_stores).and_return([nil_store])

      expect { subject.get_all_clients(config_name) }.not_to raise_error
    end
  end

  describe '#get_default_client' do
    let(:client1) { { 'id' => 'client1', 'name' => 'Client 1' } }
    let(:client2) { { 'id' => 'client2', 'name' => 'Client 2', 'IsDefault' => true } }
    let(:client3) { { 'id' => 'client3', 'name' => 'Client 3', 'isDefault' => true } }

    it 'returns client specified by defaultClientId' do
      merged_config = { 'defaultClientId' => 'client1' }
      allow(subject).to receive(:get_merged_configuration).and_return(merged_config)
      allow(subject).to receive(:get_all_clients).and_return([client1, client2])

      default_client = subject.get_default_client(config_name)

      expect(default_client).to eq(client1)
    end

    it 'returns client with IsDefault=true when no explicit defaultClientId' do
      merged_config = {}
      allow(subject).to receive(:get_merged_configuration).and_return(merged_config)
      allow(subject).to receive(:get_all_clients).and_return([client1, client2])

      default_client = subject.get_default_client(config_name)

      expect(default_client).to eq(client2)
    end

    it 'returns client with isDefault=true (lowercase)' do
      merged_config = {}
      allow(subject).to receive(:get_merged_configuration).and_return(merged_config)
      allow(subject).to receive(:get_all_clients).and_return([client1, client3])

      default_client = subject.get_default_client(config_name)

      expect(default_client).to eq(client3)
    end

    it 'returns nil when no default client found' do
      merged_config = {}
      allow(subject).to receive(:get_merged_configuration).and_return(merged_config)
      allow(subject).to receive(:get_all_clients).and_return([client1])

      default_client = subject.get_default_client(config_name)

      expect(default_client).to be_nil
    end

    it 'returns nil when defaultClientId not found in clients' do
      merged_config = { 'defaultClientId' => 'nonexistent' }
      allow(subject).to receive(:get_merged_configuration).and_return(merged_config)
      allow(subject).to receive(:get_all_clients).and_return([client1, client2])

      default_client = subject.get_default_client(config_name)

      expect(default_client).to be_nil
    end
  end

  describe '#get_client' do
    let(:client1) { { 'id' => 'client1', 'name' => 'Client 1' } }
    let(:client2) { { 'id' => 'client2', 'name' => 'Client 2' } }

    it 'returns client with matching ID' do
      allow(subject).to receive(:get_all_clients).and_return([client1, client2])

      client = subject.get_client(config_name, 'client2')

      expect(client).to eq(client2)
    end

    it 'returns nil when client ID not found' do
      allow(subject).to receive(:get_all_clients).and_return([client1, client2])

      client = subject.get_client(config_name, 'nonexistent')

      expect(client).to be_nil
    end

    it 'returns nil when no clients exist' do
      allow(subject).to receive(:get_all_clients).and_return([])

      client = subject.get_client(config_name, 'client1')

      expect(client).to be_nil
    end
  end

  describe '#get_client_private_key' do
    let(:mock_store) { double('ConfigStore') }
    let(:client_config) { { 'id' => 'client1', '_store' => mock_store } }

    it 'returns private key from client store' do
      private_key_content = 'private-key-content'
      allow(mock_store).to receive(:get_private_key).with('client1').and_return(private_key_content)

      private_key = subject.get_client_private_key(client_config)

      expect(private_key).to eq(private_key_content)
    end

    it 'returns nil when store is not present' do
      client_config_no_store = { 'id' => 'client1' }

      private_key = subject.get_client_private_key(client_config_no_store)

      expect(private_key).to be_nil
    end

    it 'returns nil when store cannot find private key' do
      allow(mock_store).to receive(:get_private_key).with('client1').and_return(nil)

      private_key = subject.get_client_private_key(client_config)

      expect(private_key).to be_nil
    end
  end

  describe '#get_writable_store' do
    let(:user_path) { '/user/path' }
    let(:system_path) { '/system/path' }

    before do
      allow(mock_environment).to receive(:get_config_path)
        .with(Eryph::ClientRuntime::Environment::ConfigStoreLocation::USER)
        .and_return(user_path)
      allow(mock_environment).to receive(:get_config_path)
        .with(Eryph::ClientRuntime::Environment::ConfigStoreLocation::SYSTEM)
        .and_return(system_path)
    end

    it 'returns system store when running as admin' do
      allow(mock_environment).to receive(:admin_user?).and_return(true)

      store = subject.get_writable_store(config_name)

      expect(store.base_path).to eq(system_path)
      expect(store.config_name).to eq(config_name)
      expect(store.environment).to eq(mock_environment)
    end

    it 'returns user store when not running as admin' do
      allow(mock_environment).to receive(:admin_user?).and_return(false)

      store = subject.get_writable_store(config_name)

      expect(store.base_path).to eq(user_path)
      expect(store.config_name).to eq(config_name)
      expect(store.environment).to eq(mock_environment)
    end
  end

  describe '#deep_merge (private method)' do
    it 'merges non-conflicting keys' do
      hash1 = { 'a' => 1, 'b' => 2 }
      hash2 = { 'c' => 3, 'd' => 4 }

      result = subject.send(:deep_merge, hash1, hash2)

      expect(result).to eq({ 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4 })
    end

    it 'overwrites simple values' do
      hash1 = { 'a' => 1, 'b' => 2 }
      hash2 = { 'a' => 10, 'c' => 3 }

      result = subject.send(:deep_merge, hash1, hash2)

      expect(result).to eq({ 'a' => 10, 'b' => 2, 'c' => 3 })
    end

    it 'deeply merges nested hashes' do
      hash1 = { 'nested' => { 'a' => 1, 'b' => 2 } }
      hash2 = { 'nested' => { 'b' => 20, 'c' => 3 } }

      result = subject.send(:deep_merge, hash1, hash2)

      expect(result).to eq({
        'nested' => { 'a' => 1, 'b' => 20, 'c' => 3 }
      })
    end

    it 'handles mixed hash and non-hash values' do
      hash1 = { 'key' => { 'nested' => 'value' } }
      hash2 = { 'key' => 'simple_value' }

      result = subject.send(:deep_merge, hash1, hash2)

      expect(result).to eq({ 'key' => 'simple_value' })
    end

    it 'does not modify original hashes' do
      hash1 = { 'a' => { 'nested' => 1 } }
      hash2 = { 'a' => { 'nested' => 2 } }
      original_hash1 = hash1.dup
      original_hash2 = hash2.dup

      subject.send(:deep_merge, hash1, hash2)

      expect(hash1).to eq(original_hash1)
      expect(hash2).to eq(original_hash2)
    end
  end
end