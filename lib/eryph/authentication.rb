require_relative 'authentication/client_credentials_lookup'
require_relative 'authentication/token_provider'
require_relative 'authentication/environment'

module Eryph
  # Authentication module for Eryph client
  # Provides OAuth2 client credentials flow with private key JWT authentication
  module Authentication
    # Error raised when authentication fails
    class AuthenticationError < StandardError; end

    # Error raised when credentials cannot be found
    class CredentialsNotFoundError < AuthenticationError; end

    # Error raised when token request fails
    class TokenRequestError < AuthenticationError; end

    class << self
      # Create a token provider using environment-based credential lookup
      # @param config [Configuration] configuration object
      # @return [TokenProvider] configured token provider
      def create_token_provider(config)
        lookup = ClientCredentialsLookup.new(Environment.new(config))
        credentials = lookup.find_credentials
        TokenProvider.new(credentials, config)
      end

      # Get an access token using the provided configuration
      # @param config [Configuration] configuration object
      # @return [String] access token
      # @raise [AuthenticationError] if authentication fails
      def get_access_token(config)
        provider = create_token_provider(config)
        provider.get_access_token
      end
    end
  end
end