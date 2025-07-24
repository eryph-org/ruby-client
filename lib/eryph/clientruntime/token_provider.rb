require 'jwt'
require 'securerandom'
require 'time'
require 'net/http'
require 'uri'
require 'json'

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
          use_system_ca: false,
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
        uri = URI(@credentials.token_endpoint)
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        
        configure_ssl(http, uri.host)
        
        http.read_timeout = @http_config[:timeout]

        request = Net::HTTP::Post.new(uri.path)
        request['Content-Type'] = 'application/x-www-form-urlencoded'
        request['User-Agent'] = @http_config[:user_agent]
        request.body = URI.encode_www_form(request_body)

        log_debug "Requesting token from #{@credentials.token_endpoint} for client #{@credentials.client_id}"
        
        response = http.request(request)
        
        unless response.is_a?(Net::HTTPSuccess)
          error_details = parse_error_response(response)
          raise TokenRequestError, "Token request failed (#{response.code}): #{error_details}"
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
        return response.message if response.body.nil? || response.body.empty?
        
        data = JSON.parse(response.body)
        error = data['error'] || 'unknown_error'
        description = data['error_description'] || response.message
        "#{error}: #{description}"
      rescue JSON::ParserError
        response.body
      end

      def configure_ssl(http, hostname)
        return unless http.use_ssl?
        
        # Basic SSL verification setting
        if @http_config[:verify_ssl]
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          
          # Handle hostname verification
          if @http_config[:verify_hostname]
            http.verify_hostname = true
          else
            http.verify_hostname = false
          end
          
          # Set CA certificate or file
          if @http_config[:ca_cert]
            # Use provided certificate
            cert_store = OpenSSL::X509::Store.new
            cert_store.add_cert(@http_config[:ca_cert])
            http.cert_store = cert_store
          elsif @http_config[:ca_file]
            # Use certificate file
            http.ca_file = @http_config[:ca_file]
          elsif @http_config[:use_system_ca]
            # Use system certificate store (Windows)
            if windows?
              configure_windows_cert_store(http, hostname)
            else
              http.cert_store = OpenSSL::X509::Store.new
              http.cert_store.set_default_paths
            end
          else
            # Use default certificate paths
            http.cert_store = OpenSSL::X509::Store.new
            http.cert_store.set_default_paths
          end
        else
          # Disable SSL verification
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          http.verify_hostname = false
        end
      end
      
      def configure_windows_cert_store(http, hostname)
        return unless windows?
        
        begin
          require 'win32/certstore'
          
          # Create certificate store
          cert_store = OpenSSL::X509::Store.new
          
          # Add certificates from Windows certificate store
          win_store = Win32::Certstore.open("ROOT")
          win_store.each do |cert|
            begin
              cert_store.add_cert(cert)
            rescue OpenSSL::X509::StoreError
              # Ignore duplicate certificates
            end
          end
          win_store.close
          
          # Also check personal store
          personal_store = Win32::Certstore.open("MY")
          personal_store.each do |cert|
            begin
              cert_store.add_cert(cert)
            rescue OpenSSL::X509::StoreError
              # Ignore duplicate certificates
            end
          end
          personal_store.close
          
          http.cert_store = cert_store
          log_debug "Configured Windows certificate store"
        rescue LoadError
          log_debug "win32-certstore gem not available, falling back to default certificate paths"
          http.cert_store = OpenSSL::X509::Store.new
          http.cert_store.set_default_paths
        rescue => e
          log_debug "Error configuring Windows certificate store: #{e.message}, falling back to default"
          http.cert_store = OpenSSL::X509::Store.new
          http.cert_store.set_default_paths
        end
      end
      
      def windows?
        RUBY_PLATFORM =~ /mswin|mingw|cygwin/
      end

      def log_debug(message)
        return unless @http_config[:logger]
        
        @http_config[:logger].debug("[TokenProvider] #{message}")
      end
    end
  end
end