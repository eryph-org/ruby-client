require 'json'
require 'fileutils'

module Eryph
  module ClientRuntime
    # Represents a configuration store for eryph client settings
    # Manages JSON configuration files and private key storage
    class ConfigStore
      STORE_DIR = '.eryph'
      PRIVATE_DIR = 'private'
      CONFIG_EXTENSION = '.config'

      # @return [String] base path for this configuration store
      attr_reader :base_path

      # @return [String] configuration name
      attr_reader :config_name

      # @return [Environment] environment abstraction
      attr_reader :environment

      # Initialize a configuration store
      # @param base_path [String] base directory path
      # @param config_name [String] configuration name
      # @param environment [Environment] environment abstraction
      def initialize(base_path, config_name, environment)
        @base_path = base_path
        @config_name = config_name
        @environment = environment
      end

      # Check if this configuration store exists
      # @return [Boolean] true if the store exists
      def exists?
        @environment.file_exists?(config_file_path)
      end

      # Get the configuration data
      # @return [Hash] parsed configuration data
      # @raise [ConfigurationError] if configuration cannot be read or parsed
      def configuration
        return {} unless exists?

        begin
          content = @environment.read_file(config_file_path)
          JSON.parse(content)
        rescue JSON::ParserError => e
          raise ConfigurationError, "Invalid JSON in configuration file #{config_file_path}: #{e.message}"
        rescue IOError => e
          raise ConfigurationError, "Cannot read configuration file #{config_file_path}: #{e.message}"
        end
      end

      # Get endpoints from this configuration store
      # @return [Hash] endpoint name -> URL mapping
      def endpoints
        config = configuration
        config['endpoints'] || {}
      end

      # Get clients from this configuration store
      # @return [Array<Hash>] array of client configurations
      def clients
        config = configuration
        config['clients'] || []
      end

      # Get the default client ID
      # @return [String, nil] default client ID
      def default_client_id
        config = configuration
        config['defaultClient']
      end

      # Get a client configuration by ID
      # @param client_id [String] client ID to lookup
      # @return [Hash, nil] client configuration or nil if not found
      def get_client(client_id)
        clients.find { |client| client['id'] == client_id }
      end

      # Get the default client configuration
      # @return [Hash, nil] default client configuration or nil if not found
      def default_client
        config = configuration
        default_client_id = config['defaultClientId']
        
        all_clients = clients
        return nil if all_clients.empty?
        
        # If explicit defaultClient is set, use that
        if default_client_id
          return all_clients.find { |client| client['id'] == default_client_id }
        end
        
        # Otherwise, return first client
        all_clients.first
      end

      # Get the private key for a client configuration
      # @param client_config [Hash] client configuration (may include '_store' key)
      # @return [String, nil] private key content or nil if not found
      def get_client_private_key(client_config)
        client_id = client_config['id']
        return nil unless client_id

        get_private_key(client_id)
      end

      # Get the private key for a client
      # @param client_id [String] client ID
      # @return [String, nil] private key content or nil if not found
      def get_private_key(client_id)
        key_path = private_key_path(client_id)
        return nil unless @environment.file_exists?(key_path)

        begin
          @environment.read_file(key_path)
        rescue IOError
          nil
        end
      end

      # Store a client configuration
      # @param client_config [Hash] client configuration
      # @raise [ConfigurationError] if configuration cannot be saved
      def store_client(client_config)
        config = configuration
        config['clients'] ||= []
        
        # Remove existing client with same ID
        config['clients'].reject! { |c| c['id'] == client_config['id'] }
        
        # Add new client
        config['clients'] << client_config
        
        # Set as default if no default exists
        config['defaultClient'] ||= client_config['id']
        
        save_configuration(config)
      end

      # Store a private key for a client
      # @param client_id [String] client ID
      # @param private_key [String] private key content (PEM format)
      # @raise [ConfigurationError] if private key cannot be saved
      def store_private_key(client_id, private_key)
        key_path = private_key_path(client_id)
        
        begin
          @environment.ensure_directory(File.dirname(key_path))
          @environment.write_file(key_path, private_key)
          
          # Set restrictive permissions on Unix-like systems
          unless @environment.windows?
            File.chmod(0600, key_path)
          end
        rescue IOError => e
          raise ConfigurationError, "Cannot store private key: #{e.message}"
        end
      end

      # Store an endpoint
      # @param endpoint_name [String] endpoint name
      # @param endpoint_url [String] endpoint URL
      # @raise [ConfigurationError] if endpoint cannot be saved
      def store_endpoint(endpoint_name, endpoint_url)
        config = configuration
        config['endpoints'] ||= {}
        config['endpoints'][endpoint_name] = endpoint_url
        save_configuration(config)
      end

      # Get the full path to the store directory
      # @return [String] store directory path
      def store_path
        File.join(@base_path, STORE_DIR)
      end

      # Get the full path to the configuration file
      # @return [String] configuration file path
      def config_file_path
        File.join(store_path, "#{@config_name}#{CONFIG_EXTENSION}")
      end

      # Get the full path to the private key directory
      # @return [String] private key directory path
      def private_key_directory
        File.join(store_path, PRIVATE_DIR)
      end

      # Get the full path to a specific private key file
      # @param client_id [String] client ID
      # @return [String] private key file path
      def private_key_path(client_id)
        File.join(private_key_directory, "#{client_id}.key")
      end

      private

      def save_configuration(config)
        begin
          @environment.ensure_directory(store_path)
          content = JSON.pretty_generate(config)
          @environment.write_file(config_file_path, content)
        rescue IOError => e
          raise ConfigurationError, "Cannot save configuration: #{e.message}"
        end
      end
    end
  end
end