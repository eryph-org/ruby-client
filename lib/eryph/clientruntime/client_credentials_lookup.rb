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

      # @return [String, nil] configuration name this client belongs to
      attr_reader :configuration

      # Initialize client credentials
      # @param client_id [String] OAuth client ID
      # @param client_name [String] client name
      # @param private_key [OpenSSL::PKey::RSA, String] RSA private key
      # @param token_endpoint [String] OAuth token endpoint URL
      # @param configuration [String, nil] configuration name
      def initialize(client_id:, client_name:, private_key:, token_endpoint:, configuration: nil)
        raise ArgumentError, "client_id cannot be nil or empty" if client_id.nil? || client_id.empty?
        raise ArgumentError, "token_endpoint cannot be nil or empty" if token_endpoint.nil? || token_endpoint.empty?
        
        @client_id = client_id
        @client_name = client_name
        @private_key = parse_private_key(private_key)
        @token_endpoint = token_endpoint
        @configuration = configuration
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
    # Supports automatic discovery across multiple configurations like .NET implementation
    class ClientCredentialsLookup
      # @return [ConfigStoresReader] configuration stores reader
      attr_reader :reader

      # @return [String, nil] configuration name for specific lookups
      attr_reader :config_name

      # Initialize the credentials lookup
      # @param reader [ConfigStoresReader] configuration stores reader
      # @param config_name [String, nil] configuration name for specific lookup, nil for automatic discovery
      def initialize(reader, config_name = nil)
        @reader = reader
        @config_name = config_name
      end

      # Find and return client credentials
      # Uses automatic discovery if no config_name specified, otherwise looks in specific config
      # @return [ClientCredentials] the discovered credentials
      # @raise [CredentialsNotFoundError, NoUserCredentialsError] if credentials cannot be found
      def find_credentials
        if @config_name
          # Find default client in specific config
          creds = get_default_credentials(@config_name)
          
          # For zero config, try system client as fallback
          if !creds && @config_name == 'zero'
            creds = get_system_client_credentials(@config_name)
          end
          
          raise CredentialsNotFoundError, "No default client found in configuration '#{@config_name}'" unless creds
          creds
        else
          # Automatic discovery across multiple configs
          configs = @reader.environment.windows? ? ['default', 'zero', 'local'] : ['default', 'local']
          find_credentials_in_configs(*configs)
        end
      end

      # Try multiple configurations in order
      # @param config_names [Array<String>] configuration names to try
      # @return [ClientCredentials] first credentials found
      # @raise [NoUserCredentialsError] if no credentials found in any config
      def find_credentials_in_configs(*config_names)
        config_names.each do |config_name|
          # Try default client first
          creds = get_default_credentials(config_name)
          return creds if creds
          
          # Try system client for zero/local configs
          if ['zero', 'local'].include?(config_name)
            creds = get_system_client_credentials(config_name)
            return creds if creds
          end
        end
        
        raise NoUserCredentialsError, "No credentials found. Please configure an eryph client."
      end

      # Get default client credentials from specific configuration
      # @param config_name [String] configuration name
      # @return [ClientCredentials, nil] credentials if found, nil otherwise
      def get_default_credentials(config_name)
        client = @reader.get_default_client(config_name)
        return nil unless client
        
        build_credentials(client, config_name)
      end

      # Get credentials by client ID from specific configuration
      # @param client_id [String] client ID to find
      # @param config_name [String] configuration name to search in
      # @return [ClientCredentials, nil] credentials if found, nil otherwise
      def get_credentials_by_client_id(client_id, config_name = 'default')
        client = @reader.get_client(config_name, client_id)
        return nil unless client
        
        build_credentials(client, config_name)
      end

      # Get credentials by client name from specific configuration
      # @param client_name [String] client name to find
      # @param config_name [String] configuration name to search in
      # @return [ClientCredentials, nil] credentials if found, nil otherwise
      def get_credentials_by_client_name(client_name, config_name = 'default')
        # Search through all clients to find by name
        all_clients = @reader.get_all_clients(config_name)
        client = all_clients.find { |c| c['name'] == client_name }
        return nil unless client
        
        build_credentials(client, config_name)
      end

      # Get system client credentials for zero/local configurations
      # @param config_name [String] configuration name ('zero' or 'local')
      # @return [ClientCredentials, nil] system credentials if available, nil otherwise
      # @raise [NoUserCredentialsError] if system client available but requires admin privileges
      def get_system_client_credentials(config_name = 'local')
        return nil unless ['zero', 'local'].include?(config_name)
        return nil unless @reader.environment.windows? || @reader.environment.linux?
        
        # Zero config only supported on Windows
        if config_name == 'zero' && !@reader.environment.windows?
          return nil
        end
        
        # Check admin privileges on Windows
        if @reader.environment.windows? && !@reader.environment.admin_user?
          raise NoUserCredentialsError, 
            "No user credentials found. System client is available but requires Administrator privileges. " +
            "Please run as Administrator (Windows) or root (Linux) to use system client."
        end
        
        # Check root privileges on Linux
        if @reader.environment.linux? && !@reader.environment.admin_user?
          raise NoUserCredentialsError,
            "No user credentials found. System client is available but requires root privileges. " +
            "Please run as root to use system client."
        end
        
        provider_info = LocalIdentityProviderInfo.new(@reader.environment, config_name)
        return nil unless provider_info.running?
        
        system_creds = provider_info.system_client_credentials
        return nil unless system_creds
        
        ClientCredentials.new(
          client_id: system_creds['id'],
          client_name: 'system-client',
          private_key: system_creds['private_key'],
          token_endpoint: "#{system_creds['identity_endpoint']}/connect/token",
          configuration: config_name
        )
      end

      # Test if credentials are available
      # @return [Boolean] true if credentials can be found
      def credentials_available?
        find_credentials
        true
      rescue CredentialsNotFoundError, NoUserCredentialsError
        false
      end
      
      private
      
      # Build credentials object from client data and config
      # @param client [Hash] client data from configuration
      # @param config_name [String] configuration name
      # @return [ClientCredentials, nil] built credentials or nil if invalid
      def build_credentials(client, config_name)
        private_key = @reader.get_client_private_key(client)
        return nil unless private_key
        
        token_endpoint = get_token_endpoint(config_name)
        return nil unless token_endpoint
        
        ClientCredentials.new(
          client_id: client['id'],
          client_name: client['name'] || client['id'],
          private_key: private_key,
          token_endpoint: token_endpoint,
          configuration: config_name
        )
      rescue ArgumentError
        nil
      end
      
      # Get token endpoint for configuration
      # @param config_name [String] configuration name
      # @return [String, nil] token endpoint URL or nil if not found
      def get_token_endpoint(config_name)
        endpoint_lookup = EndpointLookup.new(@reader, config_name)
        identity_url = endpoint_lookup.get_endpoint('identity')
        return nil unless identity_url
        
        "#{identity_url.chomp('/')}/connect/token"
      end
    end
  end
end