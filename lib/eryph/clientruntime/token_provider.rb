require 'jwt'
require 'securerandom'
require 'time'
require 'uri'
require 'json'
require 'faraday'

module Eryph
  module ClientRuntime
    # Token response structure
    class TokenResponse
      # @return [String] the access token
      attr_reader :access_token

      # @return [String] the token type (usually "Bearer")
      attr_reader :token_type

      # @return [Integer] expires in seconds
      attr_reader :expires_in

      # @return [Array<String>] granted scopes
      attr_reader :scopes

      # @return [Time] when this token was issued
      attr_reader :issued_at

      # Initialize token response
      # @param access_token [String] access token
      # @param token_type [String] token type
      # @param expires_in [Integer] expires in seconds
      # @param scopes [Array<String>] granted scopes
      def initialize(access_token:, token_type: "Bearer", expires_in:, scopes: [])
        @access_token = access_token
        @token_type = token_type
        @expires_in = expires_in.to_i
        @scopes = scopes
        @issued_at = Time.now
      end

      # Check if the token is expired or will expire soon
      # @param buffer_seconds [Integer] buffer time in seconds before considering expired
      # @return [Boolean] true if token is expired or will expire soon
      def expired?(buffer_seconds = 300)
        return true if @expires_in <= 0
        
        expires_at = @issued_at + @expires_in
        Time.now >= (expires_at - buffer_seconds)
      end

      # Get the authorization header value
      # @return [String] authorization header value
      def authorization_header
        "#{@token_type} #{@access_token}"
      end
    end

    # Provides OAuth2 access tokens using client credentials flow with JWT authentication
    # Follows the same pattern as the .NET TokenProvider
    class TokenProvider
      # @return [ClientCredentials] the client credentials
      attr_reader :credentials

      # @return [Array<String>] OAuth2 scopes
      attr_reader :scopes

      # @return [Hash] HTTP client configuration
      attr_reader :http_config

      # Initialize the token provider
      # @param credentials [ClientCredentials] client credentials
      # @param scopes [Array<String>] OAuth2 scopes
      # @param http_config [Hash] HTTP client configuration
      def initialize(credentials, scopes: ['compute:read', 'compute:write'], http_config: {})
        @credentials = credentials
        @scopes = scopes
        @http_config = default_http_config.merge(http_config)
        @current_token = nil
        @token_mutex = Mutex.new
      end

      # Get token response object, refreshing if necessary
      # @return [TokenResponse] full token response
      # @raise [TokenRequestError] if token request fails  
      def get_token
        @token_mutex.synchronize do
          if @current_token.nil? || @current_token.expired?
            @current_token = request_new_token
          end
          
          @current_token
        end
      end

      # Get an access token, refreshing if necessary
      # @return [String] access token
      # @raise [TokenRequestError] if token request fails
      def get_access_token
        @token_mutex.synchronize do
          if @current_token.nil? || @current_token.expired?
            @current_token = request_new_token
          end
          
          @current_token.access_token
        end
      end

      # Get current access token without forcing refresh (convenience method)
      # @return [String, nil] current access token or nil if no token cached
      def access_token
        @token_mutex.synchronize do
          return nil if @current_token.nil?
          
          if @current_token.expired?
            # Auto-refresh expired token
            @current_token = request_new_token
          end
          
          @current_token.access_token
        end
      end

      # Force a token refresh
      # @return [String] new access token
      # @raise [TokenRequestError] if token request fails
      def refresh_token
        @token_mutex.synchronize do
          @current_token = request_new_token
          @current_token.access_token
        end
      end

      # Get the current token response (if any)
      # @return [TokenResponse, nil] current token response
      def current_token
        @token_mutex.synchronize { @current_token }
      end

      # Get the authorization header for HTTP requests
      # @return [String] authorization header value
      def authorization_header
        token = @token_mutex.synchronize { @current_token }
        return nil unless token && !token.expired?
        
        token.authorization_header
      end

      private

      def default_http_config
        {
          timeout: 60,
          verify_ssl: true,
          ca_file: nil,
          ca_cert: nil,
          verify_hostname: true,
          user_agent: "eryph-ruby-clientruntime/#{ClientRuntime::VERSION}",
          logger: nil
        }
      end

      def request_new_token
        client_assertion = create_client_assertion
        
        request_body = {
          'grant_type' => 'client_credentials',
          'client_id' => @credentials.client_id,
          'client_assertion_type' => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
          'client_assertion' => client_assertion,
          'scope' => @scopes.join(' ')
        }

        response = make_token_request(request_body)
        parse_token_response(response)
      end

      def create_client_assertion
        now = Time.now.to_i
        
        claims = {
          'iss' => @credentials.client_id,      # issuer
          'sub' => @credentials.client_id,      # subject
          'aud' => @credentials.token_endpoint, # audience
          'jti' => SecureRandom.uuid,           # JWT ID
          'iat' => now,                         # issued at
          'exp' => now + 300                    # expires in 5 minutes
        }

        JWT.encode(claims, @credentials.private_key, 'RS256')
      end

      def make_token_request(request_body)
        log_debug "Requesting token from #{@credentials.token_endpoint} for client #{@credentials.client_id}"
        
        connection = create_faraday_connection
        
        response = connection.post do |req|
          req.url @credentials.token_endpoint
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          req.headers['User-Agent'] = @http_config[:user_agent]
          req.body = URI.encode_www_form(request_body)
        end
        
        unless response.success?
          error_details = parse_error_response(response)
          raise TokenRequestError, "Token request failed (#{response.status}): #{error_details}"
        end

        log_debug "Token request successful"
        response
      end

      def parse_token_response(response)
        data = JSON.parse(response.body)
        
        TokenResponse.new(
          access_token: data['access_token'],
          token_type: data['token_type'] || 'Bearer',
          expires_in: data['expires_in'] || 3600,
          scopes: (data['scope'] || '').split(' ')
        )
      rescue JSON::ParserError => e
        raise TokenRequestError, "Invalid JSON response from token endpoint: #{e.message}"
      rescue KeyError => e
        raise TokenRequestError, "Missing required field in token response: #{e.message}"
      end

      def parse_error_response(response)
        return response.reason_phrase if response.body.nil? || response.body.empty?
        
        data = JSON.parse(response.body)
        error = data['error'] || 'unknown_error'
        description = data['error_description'] || response.reason_phrase
        "#{error}: #{description}"
      rescue JSON::ParserError
        response.body
      end

      def create_faraday_connection
        ssl_options = build_ssl_options
        
        options = { ssl: ssl_options }
        options[:request] = { timeout: @http_config[:timeout] } if @http_config[:timeout]
        
        Faraday.new(options) do |conn|
          conn.adapter Faraday.default_adapter
        end
      end

      def build_ssl_options
        ssl_options = {}
        
        if @http_config[:verify_ssl] == false
          ssl_options[:verify] = false
        else
          ssl_options[:verify] = true
          ssl_options[:verify_hostname] = @http_config[:verify_hostname] != false
        end
        
        ssl_options[:ca_file] = @http_config[:ca_file] if @http_config[:ca_file]
        ssl_options[:ca_cert] = @http_config[:ca_cert] if @http_config[:ca_cert]
        
        ssl_options
      end

      def log_debug(message)
        return unless @http_config[:logger]
        
        @http_config[:logger].debug("[TokenProvider] #{message}")
      end
    end
  end
end