# Eryph Client Runtime
# Provides authentication, configuration, and credential lookup for eryph client libraries

require_relative 'clientruntime/version'
require_relative 'clientruntime/environment'
require_relative 'clientruntime/config_store'
require_relative 'clientruntime/config_stores_reader'
require_relative 'clientruntime/local_identity_provider_info'
require_relative 'clientruntime/client_credentials_lookup'
require_relative 'clientruntime/token_provider'
require_relative 'clientruntime/endpoint_lookup'

module Eryph
  # Client runtime module providing authentication and configuration services
  # This module can be used by multiple eryph client libraries (compute, identity, etc.)
  module ClientRuntime
    # Error raised when authentication fails
    class AuthenticationError < StandardError; end

    # Error raised when credentials cannot be found
    class CredentialsNotFoundError < AuthenticationError; end

    # Error raised when token request fails
    class TokenRequestError < AuthenticationError; end

    # Error raised when configuration is invalid
    class ConfigurationError < StandardError; end

    class << self
      # Create a client credentials lookup for the specified configuration
      # @param config_name [String] configuration name (default: 'default')
      # @param endpoint_name [String] endpoint name for lookup
      # @return [ClientCredentialsLookup] configured lookup instance
      def create_credentials_lookup(config_name: 'default', endpoint_name: nil)
        environment = Environment.new
        reader = ConfigStoresReader.new(environment)
        endpoint_lookup = EndpointLookup.new(reader, config_name)
        
        ClientCredentialsLookup.new(reader, endpoint_lookup, config_name, endpoint_name)
      end

      # Get an access token for the specified configuration and endpoint
      # @param config_name [String] configuration name (default: 'default')
      # @param endpoint_name [String] endpoint name for lookup
      # @param scopes [Array<String>] OAuth2 scopes
      # @return [String] access token
      # @raise [AuthenticationError] if authentication fails
      def get_access_token(config_name: 'default', endpoint_name: nil, scopes: ['compute:read', 'compute:write'])
        lookup = create_credentials_lookup(config_name: config_name, endpoint_name: endpoint_name)
        credentials = lookup.find_credentials
        provider = TokenProvider.new(credentials, scopes: scopes)
        provider.get_access_token
      end

      # Test if credentials are available for the specified configuration
      # @param config_name [String] configuration name (default: 'default')
      # @param endpoint_name [String] endpoint name for lookup
      # @return [Boolean] true if credentials are available
      def credentials_available?(config_name: 'default', endpoint_name: nil)
        lookup = create_credentials_lookup(config_name: config_name, endpoint_name: endpoint_name)
        lookup.find_credentials
        true
      rescue CredentialsNotFoundError
        false
      end

      # Check if eryph-zero is running locally
      # @param identity_provider_name [String] identity provider name
      # @return [Boolean] true if eryph-zero is running
      def zero_running?(identity_provider_name: 'zero')
        environment = Environment.new
        provider_info = LocalIdentityProviderInfo.new(environment, identity_provider_name)
        provider_info.running?
      end

      # Get endpoints from running eryph-zero instance
      # @param identity_provider_name [String] identity provider name
      # @return [Hash] endpoint name -> URI mapping
      def zero_endpoints(identity_provider_name: 'zero')
        environment = Environment.new
        provider_info = LocalIdentityProviderInfo.new(environment, identity_provider_name)
        
        if provider_info.running?
          # Convert URI objects to strings
          provider_info.endpoints.transform_values(&:to_s)
        else
          {}
        end
      end
    end
  end
end