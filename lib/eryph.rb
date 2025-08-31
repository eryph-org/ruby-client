# Eryph Ruby Compute Client
# Main entry point for the Eryph compute client library

require_relative 'eryph/version'
require_relative 'eryph/clientruntime'
require_relative 'eryph/compute'

# Only load generated client if dependencies are available
begin
  require_relative 'eryph/compute/generated'
rescue LoadError => e
  # Generated client dependencies not available, API clients will fall back to placeholder mode
  warn "Warning: Generated compute client not available (#{e.message}). Run generate.ps1 to create the API client."
end

module Eryph
  class << self
    # Create a new compute client instance using configuration-based credentials
    # @param config_name [String] configuration name (default: 'default')
    # @param endpoint_name [String] endpoint name for lookup (default: auto-detect)
    # @param options [Hash] additional options
    # @option options [Logger] :logger logger instance
    # @option options [Array<String>] :scopes OAuth2 scopes
    # @option options [Hash] :ssl_config SSL configuration options
    # @option options [Boolean] :verify_ssl (true) whether to verify SSL certificates
    # @option options [Boolean] :verify_hostname (true) whether to verify hostname
    # @option options [String] :ca_file path to CA certificate file
    # @option options [OpenSSL::X509::Certificate] :ca_cert CA certificate object
    # @return [Compute::Client] a new compute client instance
    # @example
    #   client = Eryph.compute_client
    #   client = Eryph.compute_client('zero')
    #   client = Eryph.compute_client('zero', verify_ssl: false)
    #   client = Eryph.compute_client('production', endpoint_name: 'compute')
    def compute_client(config_name = 'default', endpoint_name: nil, **options)
      # Extract SSL config from options
      ssl_keys = [:verify_ssl, :verify_hostname, :ca_file, :ca_cert]
      ssl_config = options.select { |key, _| ssl_keys.include?(key) }
      
      # Extract other specific parameters that need special handling
      scopes = options[:scopes]
      logger = options[:logger]
      
      # Remove handled options from the remaining options
      handled_keys = ssl_keys + [:scopes, :logger]
      remaining_options = options.reject { |key, _| handled_keys.include?(key) }
      
      ssl_config_hash = ssl_config.empty? ? {} : { ssl_config: ssl_config }
      
      # Pass parameters explicitly to ensure proper handling
      client_params = { endpoint_name: endpoint_name }
      client_params[:logger] = logger if logger
      client_params[:scopes] = scopes if scopes
      
      Compute::Client.new(config_name, **client_params.merge(ssl_config_hash).merge(remaining_options))
    end

    # Create a compute client using explicit credentials (for compatibility)
    # @param endpoint [String] compute API endpoint URL
    # @param client_id [String] OAuth2 client ID
    # @param private_key [String, OpenSSL::PKey::RSA] private key for authentication
    # @param options [Hash] additional options
    # @return [Compute::Client] a new compute client instance
    # @example
    #   client = Eryph.compute_client_with_credentials(
    #     endpoint: "https://eryph.example.com/compute",
    #     client_id: "your-client-id", 
    #     private_key: File.read("private-key.pem")
    #   )
    def compute_client_with_credentials(endpoint:, client_id:, private_key:, **options)
      Compute::Client.new_with_credentials(
        endpoint: endpoint,
        client_id: client_id,
        private_key: private_key,
        **options
      )
    end

    # Test if credentials are available for the specified configuration
    # @param config_name [String] configuration name (default: 'default')
    # @param endpoint_name [String] endpoint name for lookup
    # @return [Boolean] true if credentials are available
    def credentials_available?(config_name = 'default', endpoint_name: nil)
      ClientRuntime.credentials_available?(config_name: config_name, endpoint_name: endpoint_name)
    end

    # Check if eryph-zero is running locally
    # @return [Boolean] true if eryph-zero is running
    def zero_running?
      ClientRuntime.zero_running?
    end

    # Get endpoints from running eryph-zero instance
    # @return [Hash] endpoint name -> URL mapping
    def zero_endpoints
      ClientRuntime.zero_endpoints
    end
  end
end