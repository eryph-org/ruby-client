require 'openssl'

module Eryph
  module ClientRuntime
    # Client credentials structure
    # Holds the information needed for OAuth2 client credentials flow
    class ClientCredentials
      # @return [String] OAuth client ID
      attr_reader :client_id

      # @return [String] client name
      attr_reader :client_name

      # @return [OpenSSL::PKey::RSA] RSA private key for JWT signing
      attr_reader :private_key

      # @return [String] OAuth token endpoint URL
      attr_reader :token_endpoint

      # Initialize client credentials
      # @param client_id [String] OAuth client ID
      # @param client_name [String] client name
      # @param private_key [OpenSSL::PKey::RSA, String] RSA private key
      # @param token_endpoint [String] OAuth token endpoint URL
      def initialize(client_id:, client_name:, private_key:, token_endpoint:)
        raise ArgumentError, "client_id cannot be nil or empty" if client_id.nil? || client_id.empty?
        raise ArgumentError, "token_endpoint cannot be nil or empty" if token_endpoint.nil? || token_endpoint.empty?
        
        @client_id = client_id
        @client_name = client_name
        @private_key = parse_private_key(private_key)
        @token_endpoint = token_endpoint
      end

      private

      def parse_private_key(key)
        raise ArgumentError, "private_key cannot be nil" if key.nil?
        
        case key
        when OpenSSL::PKey::RSA
          key
        when String
          raise ArgumentError, "private_key cannot be empty" if key.empty?
          OpenSSL::PKey::RSA.new(key)
        else
          raise ArgumentError, "private_key must be an RSA key or PEM string"
        end
      rescue OpenSSL::PKey::RSAError => e
        raise ArgumentError, "Invalid RSA private key: #{e.message}"
      end
    end

    # Looks up client credentials from configuration stores
    # Follows the same pattern as the .NET ClientCredentialsLookup
    class ClientCredentialsLookup
      # @return [ConfigStoresReader] configuration stores reader
      attr_reader :reader

      # @return [EndpointLookup] endpoint lookup service
      attr_reader :endpoint_lookup

      # @return [String] configuration name
      attr_reader :config_name

      # @return [String, nil] specific endpoint name for lookup
      attr_reader :endpoint_name

      # Initialize the credentials lookup
      # @param reader [ConfigStoresReader] configuration stores reader
      # @param endpoint_lookup [EndpointLookup] endpoint lookup service
      # @param config_name [String] configuration name
      # @param endpoint_name [String, nil] specific endpoint name for lookup
      def initialize(reader, endpoint_lookup, config_name, endpoint_name = nil)
        @reader = reader
        @endpoint_lookup = endpoint_lookup
        @config_name = config_name
        @endpoint_name = endpoint_name
      end

      # Find and return client credentials
      # @return [ClientCredentials] the discovered credentials
      # @raise [CredentialsNotFoundError] if credentials cannot be found
      def find_credentials
        # Try to find default client first
        client = find_client
        raise CredentialsNotFoundError, "No client configuration found for config '#{@config_name}'" unless client

        # Get private key for the client
        private_key = @reader.get_client_private_key(client)
        raise CredentialsNotFoundError, "No private key found for client '#{client['id']}'" unless private_key

        # Get token endpoint
        token_endpoint = find_token_endpoint
        raise CredentialsNotFoundError, "No identity endpoint found for config '#{@config_name}'" unless token_endpoint

        begin
          ClientCredentials.new(
            client_id: client['id'],
            client_name: client['name'] || client['id'],
            private_key: private_key,
            token_endpoint: token_endpoint
          )
        rescue ArgumentError => e
          raise CredentialsNotFoundError, "Invalid credentials found: #{e.message}"
        end
      end

      # Test if credentials are available
      # @return [Boolean] true if credentials can be found
      def credentials_available?
        find_credentials
        true
      rescue CredentialsNotFoundError
        false
      end

      private

      def find_client
        # First try to get the default client
        client = @reader.get_default_client(@config_name)
        return client if client

        # If no default client, try to find any client
        all_clients = @reader.get_all_clients(@config_name)
        return all_clients.first if all_clients.any?

        # Special handling for 'zero' configuration
        if @config_name.downcase == 'zero'
          return find_zero_client
        end

        nil
      end

      def find_zero_client
        require_relative 'local_identity_provider_info'
        
        # Try to get system client from running eryph-zero instance
        provider_info = LocalIdentityProviderInfo.new(@reader.environment, 'zero')
        
        if provider_info.running?
          system_client = provider_info.system_client_credentials
          
          if system_client
            # Create a virtual store for the system client
            virtual_store = Object.new
            virtual_store.define_singleton_method(:get_private_key) do |client_id|
              system_client['private_key'] if client_id == system_client['id']
            end
            
            return {
              'id' => system_client['id'],
              'name' => system_client['name'],
              '_store' => virtual_store,
              '_identity_endpoint' => system_client['identity_endpoint']
            }
          end
        end

        # No fallback - if system client is not available, return nil
        nil
      end

      def find_token_endpoint
        # For zero configuration with system client, use the direct identity endpoint
        if @config_name.downcase == 'zero'
          client = find_client
          if client && client['_identity_endpoint']
            base_url = client['_identity_endpoint'].chomp('/')
            return "#{base_url}/connect/token"
          end
        end

        # Determine endpoint name based on configuration
        endpoint_name = @endpoint_name || determine_endpoint_name

        # Get the endpoint URL
        endpoint_url = @endpoint_lookup.get_endpoint(endpoint_name)
        return nil unless endpoint_url

        # Construct token endpoint URL
        base_url = endpoint_url.chomp('/')
        "#{base_url}/connect/token"
      end

      def determine_endpoint_name
        # Default endpoint name based on configuration
        case @config_name.downcase
        when 'zero'
          'identity'
        else
          'identity'
        end
      end
    end
  end
end