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
    # Create compute client with automatic or specific credential discovery
    # @param config_name [String, nil] configuration name for specific config, nil for automatic discovery
    # @param client_id [String, nil] specific client ID to use
    # @param options [Hash] additional options
    # @option options [Logger] :logger logger instance
    # @option options [Array<String>] :scopes OAuth2 scopes
    # @option options [Hash] :ssl_config SSL configuration options
    # @option options [Environment] :environment environment for dependency injection
    # @return [Compute::Client] a new compute client instance
    # @example Automatic discovery
    #   client = Eryph.compute_client
    # @example Specific configuration
    #   client = Eryph.compute_client('zero')
    # @example Specific client ID
    #   client = Eryph.compute_client('myconfig', client_id: 'my-client-id')
    # @example With options
    #   client = Eryph.compute_client(logger: my_logger, ssl_config: { verify_ssl: false })
    def compute_client(config_name = nil, client_id: nil, **options)
      Compute::Client.new(
        config_name,
        client_id: client_id,
        logger: options[:logger],
        scopes: options[:scopes],
        ssl_config: options[:ssl_config] || {},
        environment: options[:environment]
      )
    end

    # Test if credentials are available for the specified configuration
    # @param config_name [String, nil] configuration name, nil for automatic discovery
    # @return [Boolean] true if credentials are available
    # @example
    #   Eryph.credentials_available?           # automatic discovery
    #   Eryph.credentials_available?('zero')   # specific config
    def credentials_available?(config_name = nil)
      ClientRuntime.credentials_available?(config_name: config_name)
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
