module Eryph
  module ClientRuntime
    # Reads configuration from multiple configuration stores
    # Follows the hierarchy: Current Directory -> User -> System
    class ConfigStoresReader
      # @return [Environment] environment abstraction
      attr_reader :environment

      # Initialize the configuration stores reader
      # @param environment [Environment] environment abstraction
      def initialize(environment)
        @environment = environment
      end

      # Get all configuration stores for the specified configuration name
      # @param config_name [String] configuration name
      # @return [Array<ConfigStore>] array of configuration stores in priority order
      def get_stores(config_name)
        locations = [
          Environment::ConfigStoreLocation::CURRENT_DIRECTORY,
          Environment::ConfigStoreLocation::USER,
          Environment::ConfigStoreLocation::SYSTEM
        ]

        locations.map do |location|
          base_path = @environment.get_config_path(location)
          ConfigStore.new(base_path, config_name, @environment)
        end
      end

      # Get all existing configuration stores for the specified configuration name
      # @param config_name [String] configuration name
      # @return [Array<ConfigStore>] array of existing configuration stores in priority order
      def get_existing_stores(config_name)
        get_stores(config_name).select(&:exists?)
      end

      # Get merged configuration from all stores
      # @param config_name [String] configuration name
      # @return [Hash] merged configuration data
      def get_merged_configuration(config_name)
        stores = get_existing_stores(config_name)
        merged_config = {}

        # Merge configurations in reverse order (system -> user -> current)
        # so that higher priority stores override lower priority ones
        stores.reverse.each do |store|
          config = store.configuration
          merged_config = deep_merge(merged_config, config)
        end

        merged_config
      end

      # Get all endpoints from all stores
      # @param config_name [String] configuration name
      # @return [Hash] endpoint name -> URL mapping from all stores
      def get_all_endpoints(config_name)
        merged_config = get_merged_configuration(config_name)
        merged_config['endpoints'] || {}
      end

      # Get all clients from all stores
      # @param config_name [String] configuration name
      # @return [Array<Hash>] array of all client configurations
      def get_all_clients(config_name)
        stores = get_existing_stores(config_name)
        all_clients = []

        stores.each do |store|
          clients = store.clients
          next unless clients
          
          clients.each do |client|
            # Add store reference to client for private key lookup
            client_with_store = client.dup
            client_with_store['_store'] = store
            all_clients << client_with_store
          end
        end

        # Remove duplicates by ID, keeping the highest priority (first found)
        seen_ids = Set.new
        all_clients.select do |client|
          if seen_ids.include?(client['id'])
            false
          else
            seen_ids.add(client['id'])
            true
          end
        end
      end

      # Get the default client configuration
      # @param config_name [String] configuration name
      # @return [Hash, nil] default client configuration or nil if not found
      def get_default_client(config_name)
        merged_config = get_merged_configuration(config_name)
        default_client_id = merged_config['defaultClientId']
        
        all_clients = get_all_clients(config_name)
        
        # If explicit defaultClient is set, use that
        if default_client_id
          return all_clients.find { |client| client['id'] == default_client_id }
        end
        
        # Otherwise, look for client with IsDefault=true (PowerShell -AsDefault flag)
        # Try both case variations since PowerShell uses IsDefault, Ruby might use isDefault
        default_client = all_clients.find { |client| client['IsDefault'] == true || client['isDefault'] == true }
        return default_client if default_client
        
        # No explicit default found
        nil
      end

      # Get a specific client configuration by ID
      # @param config_name [String] configuration name
      # @param client_id [String] client ID to lookup
      # @return [Hash, nil] client configuration or nil if not found
      def get_client(config_name, client_id)
        all_clients = get_all_clients(config_name)
        all_clients.find { |client| client['id'] == client_id }
      end

      # Get the private key for a client
      # @param client_config [Hash] client configuration (must include '_store' key)
      # @return [String, nil] private key content or nil if not found
      def get_client_private_key(client_config)
        store = client_config['_store']
        return nil unless store

        store.get_private_key(client_config['id'])
      end

      # Get the writable store for the current user
      # @param config_name [String] configuration name
      # @return [ConfigStore] user configuration store
      def get_writable_store(config_name)
        if @environment.admin_user?
          # If running as admin, prefer system store
          base_path = @environment.get_config_path(Environment::ConfigStoreLocation::SYSTEM)
        else
          # Otherwise use user store
          base_path = @environment.get_config_path(Environment::ConfigStoreLocation::USER)
        end

        ConfigStore.new(base_path, config_name, @environment)
      end

      private

      # Deep merge two hashes
      # @param hash1 [Hash] first hash
      # @param hash2 [Hash] second hash
      # @return [Hash] merged hash
      def deep_merge(hash1, hash2)
        result = hash1.dup

        hash2.each do |key, value|
          if result[key].is_a?(Hash) && value.is_a?(Hash)
            result[key] = deep_merge(result[key], value)
          else
            result[key] = value
          end
        end

        result
      end
    end
  end
end