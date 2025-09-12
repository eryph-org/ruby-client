require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::ConfigStoresReader do
  # Test with real business logic - Environment is the only mocked boundary
  describe 'real business logic tests' do
    let(:test_environment) { TestEnvironment.new }
    let(:reader) { described_class.new(test_environment) }

    describe '#initialize' do
      it 'stores environment reference' do
        expect(reader.environment).to eq(test_environment)
      end
    end

    describe '#get_stores' do
      it 'returns stores for all three locations in priority order' do
        stores = reader.get_stores('test')

        expect(stores).to have_attributes(size: 3)
        expect(stores[0]).to be_a(Eryph::ClientRuntime::ConfigStore)
        expect(stores[0].base_path).to eq(test_environment.get_config_path(:current_directory))
        expect(stores[1].base_path).to eq(test_environment.get_config_path(:user))
        expect(stores[2].base_path).to eq(test_environment.get_config_path(:system))
      end

      it 'creates stores with correct config name' do
        stores = reader.get_stores('production')

        stores.each do |store|
          expect(store.config_name).to eq('production')
        end
      end
    end

    describe '#get_existing_stores' do
      it 'returns only existing stores' do
        # Setup: only user store exists
        user_config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'test.config'
        )
        test_environment.add_config_file(user_config_path, { 'test' => 'data' })

        existing_stores = reader.get_existing_stores('test')

        expect(existing_stores).to have_attributes(size: 1)
        expect(existing_stores[0].base_path).to eq(test_environment.get_config_path(:user))
      end

      it 'returns empty array when no stores exist' do
        existing_stores = reader.get_existing_stores('nonexistent')

        expect(existing_stores).to be_empty
      end

      it 'returns multiple existing stores in priority order' do
        # Setup: user and system stores exist (current directory does not)
        user_config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'test.config'
        )
        system_config_path = File.join(
          test_environment.get_config_path(:system),
          '.eryph',
          'test.config'
        )

        test_environment.add_config_file(user_config_path, { 'user' => 'data' })
        test_environment.add_config_file(system_config_path, { 'system' => 'data' })

        existing_stores = reader.get_existing_stores('test')

        expect(existing_stores).to have_attributes(size: 2)
        expect(existing_stores[0].base_path).to eq(test_environment.get_config_path(:user))
        expect(existing_stores[1].base_path).to eq(test_environment.get_config_path(:system))
      end
    end

    describe '#get_merged_configuration' do
      it 'merges configurations with correct priority' do
        # Setup: system has base config, user overrides some values
        user_config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'test.config'
        )
        system_config_path = File.join(
          test_environment.get_config_path(:system),
          '.eryph',
          'test.config'
        )

        system_config = {
          'endpoints' => { 'identity' => 'https://system.local/identity' },
          'clients' => [{ 'id' => 'system-client' }],
          'timeout' => 30,
        }
        user_config = {
          'endpoints' => { 'identity' => 'https://user.local/identity' }, # Override
          'clients' => [{ 'id' => 'user-client' }], # Override
          'debug' => true, # Additional
        }

        test_environment.add_config_file(system_config_path, system_config)
        test_environment.add_config_file(user_config_path, user_config)

        merged = reader.get_merged_configuration('test')

        # User config should override system config
        expect(merged['endpoints']['identity']).to eq('https://user.local/identity')
        expect(merged['clients']).to eq([{ 'id' => 'user-client' }])
        expect(merged['debug']).to be true
        expect(merged['timeout']).to eq(30) # From system, not overridden
      end

      it 'returns empty hash when no configurations exist' do
        merged = reader.get_merged_configuration('nonexistent')

        expect(merged).to eq({})
      end

      it 'handles single configuration store' do
        user_config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'test.config'
        )
        config_data = { 'clients' => [{ 'id' => 'test-client' }] }

        test_environment.add_config_file(user_config_path, config_data)

        merged = reader.get_merged_configuration('test')

        expect(merged).to eq(config_data)
      end
    end

    describe '#get_all_clients' do
      it 'returns clients from all stores with store reference' do
        # Setup multiple stores with clients
        user_config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'test.config'
        )
        system_config_path = File.join(
          test_environment.get_config_path(:system),
          '.eryph',
          'test.config'
        )

        user_config = { 'clients' => [{ 'id' => 'user-client', 'name' => 'User Client' }] }
        system_config = { 'clients' => [{ 'id' => 'system-client', 'name' => 'System Client' }] }

        test_environment.add_config_file(user_config_path, user_config)
        test_environment.add_config_file(system_config_path, system_config)

        all_clients = reader.get_all_clients('test')

        expect(all_clients).to have_attributes(size: 2)

        user_client = all_clients.find { |c| c['id'] == 'user-client' }
        system_client = all_clients.find { |c| c['id'] == 'system-client' }

        expect(user_client).to include('id' => 'user-client', 'name' => 'User Client')
        expect(system_client).to include('id' => 'system-client', 'name' => 'System Client')

        # Check that _store reference is added
        expect(user_client['_store']).to be_a(Eryph::ClientRuntime::ConfigStore)
        expect(system_client['_store']).to be_a(Eryph::ClientRuntime::ConfigStore)
      end

      it 'returns empty array when no clients exist' do
        all_clients = reader.get_all_clients('nonexistent')

        expect(all_clients).to eq([])
      end
    end

    describe '#get_client' do
      before do
        # Setup clients in different stores
        user_config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'test.config'
        )
        system_config_path = File.join(
          test_environment.get_config_path(:system),
          '.eryph',
          'test.config'
        )

        user_config = { 'clients' => [{ 'id' => 'user-client', 'name' => 'User Client' }] }
        system_config = { 'clients' => [{ 'id' => 'system-client', 'name' => 'System Client' }] }

        test_environment.add_config_file(user_config_path, user_config)
        test_environment.add_config_file(system_config_path, system_config)
      end

      it 'finds client by ID across all stores' do
        user_client = reader.get_client('test', 'user-client')
        system_client = reader.get_client('test', 'system-client')

        expect(user_client).to include('id' => 'user-client', 'name' => 'User Client')
        expect(system_client).to include('id' => 'system-client', 'name' => 'System Client')
      end

      it 'returns nil for non-existent client' do
        client = reader.get_client('test', 'missing-client')

        expect(client).to be_nil
      end
    end

    describe '#get_default_client' do
      context 'with explicit default client ID in merged config' do
        before do
          user_config_path = File.join(
            test_environment.get_config_path(:user),
            '.eryph',
            'test.config'
          )

          config_data = {
            'clients' => [
              { 'id' => 'client-1', 'name' => 'First Client' },
              { 'id' => 'client-2', 'name' => 'Second Client' },
            ],
            'defaultClientId' => 'client-2',
          }

          test_environment.add_config_file(user_config_path, config_data)
        end

        it 'returns client specified by defaultClientId' do
          default_client = reader.get_default_client('test')

          expect(default_client).to include('id' => 'client-2', 'name' => 'Second Client')
        end
      end

      context 'without explicit default client ID' do
        before do
          user_config_path = File.join(
            test_environment.get_config_path(:user),
            '.eryph',
            'test.config'
          )

          config_data = {
            'clients' => [
              { 'id' => 'client-1', 'name' => 'First Client', 'IsDefault' => true },
              { 'id' => 'client-2', 'name' => 'Second Client' },
            ],
          }

          test_environment.add_config_file(user_config_path, config_data)
        end

        it 'returns client with IsDefault flag' do
          default_client = reader.get_default_client('test')

          expect(default_client).to include('id' => 'client-1', 'name' => 'First Client')
        end
      end

      it 'returns nil when no clients exist' do
        default_client = reader.get_default_client('nonexistent')

        expect(default_client).to be_nil
      end
    end

    describe '#get_client_private_key' do
      let(:test_key) { OpenSSL::PKey::RSA.generate(2048).to_pem }

      it 'retrieves private key using client store reference' do
        # Setup client with store reference
        user_config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'test.config'
        )
        key_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'private',
          'test-client.key'
        )

        test_environment.add_config_file(user_config_path, {
                                           'clients' => [{ 'id' => 'test-client', 'name' => 'Test Client' }],
                                         })
        test_environment.add_private_key_file(key_path, test_key)

        client = reader.get_client('test', 'test-client')
        private_key = reader.get_client_private_key(client)

        expect(private_key).to eq(test_key)
      end

      it 'returns nil when client has no store reference' do
        client = { 'id' => 'test-client' }

        private_key = reader.get_client_private_key(client)

        expect(private_key).to be_nil
      end

      it 'returns nil when private key file does not exist' do
        # Setup client but no private key file
        user_config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'test.config'
        )

        test_environment.add_config_file(user_config_path, {
                                           'clients' => [{ 'id' => 'test-client', 'name' => 'Test Client' }],
                                         })

        client = reader.get_client('test', 'test-client')
        private_key = reader.get_client_private_key(client)

        expect(private_key).to be_nil
      end
    end
  end

  # Special case tests - configuration parsing edge cases
  describe 'configuration merging edge cases' do
    let(:test_environment) { TestEnvironment.new }
    let(:reader) { described_class.new(test_environment) }

    it 'handles empty configurations gracefully' do
      user_config_path = File.join(
        test_environment.get_config_path(:user),
        '.eryph',
        'test.config'
      )

      test_environment.add_config_file(user_config_path, {})

      merged = reader.get_merged_configuration('test')

      expect(merged).to eq({})
    end

    it 'handles configurations with null values' do
      user_config_path = File.join(
        test_environment.get_config_path(:user),
        '.eryph',
        'test.config'
      )

      config_with_nulls = {
        'endpoints' => nil,
        'clients' => [{ 'id' => 'test-client', 'name' => nil }],
      }

      test_environment.add_config_file(user_config_path, config_with_nulls)

      merged = reader.get_merged_configuration('test')

      expect(merged['endpoints']).to be_nil
      expect(merged['clients'][0]['name']).to be_nil
    end
  end
end
