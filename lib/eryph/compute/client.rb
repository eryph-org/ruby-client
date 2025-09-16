require 'logger'
require 'set'

module Eryph
  module Compute
    # Main client class for the Eryph Compute API
    # Provides a high-level interface to the compute API with automatic authentication
    class Client
      # @return [String] configuration name used for this client
      attr_reader :config_name

      # @return [ClientRuntime::TokenProvider] token provider for authentication
      attr_reader :token_provider

      # @return [Logger] logger instance
      attr_reader :logger

      # Initialize compute client with automatic or specific credential discovery
      # @param config_name [String, nil] configuration name for specific config, nil for automatic discovery
      # @param client_id [String, nil] specific client ID to use
      # @param logger [Logger, nil] logger instance
      # @param scopes [Array<String>] OAuth2 scopes
      # @param ssl_config [Hash] SSL configuration options
      # @param environment [ClientRuntime::Environment, nil] environment instance for dependency injection
      # @option ssl_config [Boolean] :verify_ssl (true) whether to verify SSL certificates
      # @option ssl_config [Boolean] :verify_hostname (true) whether to verify hostname
      # @option ssl_config [String] :ca_file path to CA certificate file
      # @option ssl_config [OpenSSL::X509::Certificate] :ca_cert CA certificate object
      def initialize(config_name = nil, client_id: nil, logger: nil, scopes: nil, ssl_config: {}, environment: nil)
        @logger = logger || default_logger
        @ssl_config = ssl_config || {}
        @environment = environment || ClientRuntime::Environment.new

        # Discover credentials based on parameters
        reader = ClientRuntime::ConfigStoresReader.new(@environment, logger: @logger)

        if client_id && config_name
          # Specific client in specific config - no fallback
          lookup = ClientRuntime::ClientCredentialsLookup.new(reader, config_name, logger: @logger)
          @credentials = lookup.get_credentials_by_client_id(client_id, config_name)
          unless @credentials
            raise ClientRuntime::CredentialsNotFoundError,
                  "Client '#{client_id}' not found in configuration '#{config_name}'"
          end

        elsif client_id
          # Find client in any config
          @credentials = find_client_in_any_config(reader, client_id)
          unless @credentials
            raise ClientRuntime::CredentialsNotFoundError,
                  "Client '#{client_id}' not found in any configuration"
          end

        elsif config_name
          # Default client in specific config
          lookup = ClientRuntime::ClientCredentialsLookup.new(reader, config_name, logger: @logger)
          @credentials = lookup.find_credentials

        else
          # Automatic discovery
          lookup = ClientRuntime::ClientCredentialsLookup.new(reader, logger: @logger)
          @credentials = lookup.find_credentials
        end

        @config_name = @credentials.configuration

        # Get compute endpoint for the discovered configuration
        endpoint_lookup = ClientRuntime::EndpointLookup.new(reader, @config_name, logger: @logger)
        @compute_endpoint = endpoint_lookup.endpoint('compute')
        unless @compute_endpoint
          raise ClientRuntime::ConfigurationError,
                "Compute endpoint not found in configuration '#{@config_name}'"
        end

        # Create token provider
        @token_provider = ClientRuntime::TokenProvider.new(
          @credentials,
          scopes: scopes || default_scopes,
          http_config: { logger: @logger }.merge(@ssl_config)
        )
      end

      # Test the connection and authentication
      # @return [Boolean] true if connection and authentication work
      def test_connection
        # Test authentication by ensuring we can get a valid token
        token = @token_provider.ensure_access_token
        !token.nil? && !token.empty?
      rescue StandardError => e
        @logger.error "Connection test failed: #{e.message}"
        false
      end

      # Get the current access token
      # @return [String] access token
      def access_token
        @token_provider.access_token
      end

      # Refresh the authentication token
      # @return [String] new access token
      def refresh_token
        @token_provider.refresh_token
      end

      # Get the authorization header for HTTP requests
      # @return [String] authorization header value
      def authorization_header
        @token_provider.authorization_header
      end

      # Access the catlets API
      # @return [Eryph::ComputeClient::CatletsApi] catlets API client
      def catlets
        @catlets ||= create_api_client('catlets', 'CatletsApi')
      end

      # Access the operations API
      # @return [Eryph::ComputeClient::OperationsApi] operations API client
      def operations
        @operations ||= create_api_client('operations', 'OperationsApi')
      end

      # Access the projects API
      # @return [Eryph::ComputeClient::ProjectsApi] projects API client
      def projects
        @projects ||= create_api_client('projects', 'ProjectsApi')
      end

      # Access the virtual disks API
      # @return [Eryph::ComputeClient::VirtualDisksApi] virtual disks API client
      def virtual_disks
        @virtual_disks ||= create_api_client('virtual_disks', 'VirtualDisksApi')
      end

      # Access the virtual networks API
      # @return [Eryph::ComputeClient::VirtualNetworksApi] virtual networks API client
      def virtual_networks
        @virtual_networks ||= create_api_client('virtual_networks', 'VirtualNetworksApi')
      end

      # Access the genes API
      # @return [Eryph::ComputeClient::GenesApi] genes API client
      def genes
        @genes ||= create_api_client('genes', 'GenesApi')
      end

      # Access the version API
      # @return [Eryph::ComputeClient::VersionApi] version API client
      def version
        @version ||= create_api_client('version', 'VersionApi')
      end

      # Get the compute endpoint URL being used by this client
      # @return [String] the compute endpoint URL
      def compute_endpoint_url
        @compute_endpoint
      end

      # Wait for an operation to complete with optional callbacks for progress tracking
      # @param operation_id [String] the operation ID to wait for
      # @param timeout [Integer] timeout in seconds (default: 300)
      # @param poll_interval [Integer] polling interval in seconds (default: 5)
      # @return [OperationResult] the completed operation result wrapper
      # @raise [Timeout::Error] if the operation times out
      # @yield [event_type, data] callback for operation events
      # @yieldparam event_type [Symbol] :log_entry, :task_new, :task_update, :resource_new, :status
      # @yieldparam data [Object] the event data (log entry, task, resource, or operation)
      def wait_for_operation(operation_id, timeout: 300, poll_interval: 5)
        @logger.info "Waiting for operation #{operation_id} to complete (timeout: #{timeout}s)..."

        start_time = Time.now
        last_timestamp = Time.parse('2018-01-01')
        processed_log_ids = Set.new
        processed_task_ids = Set.new
        processed_resource_ids = Set.new

        loop do
          # Get raw JSON using debug_return_type to work around discriminated union bug
          raw_json = nil
          begin
            raw_json = operations.operations_get(
              operation_id,
              expand: 'logs,tasks,resources',
              log_time_stamp: last_timestamp,
              debug_return_type: 'String'
            )
            @logger.debug "Raw JSON captured: #{raw_json ? 'YES' : 'NO'}"
          rescue StandardError => e
            @logger.debug "Failed to capture raw JSON: #{e.message}"
          end

          # Get normal deserialized operation
          operation = operations.operations_get(
            operation_id,
            expand: 'logs,tasks,resources',
            log_time_stamp: last_timestamp
          )

          # Process NEW log entries only
          if operation.log_entries && block_given?
            operation.log_entries.each do |log_entry|
              next if processed_log_ids.include?(log_entry.id)

              processed_log_ids.add(log_entry.id)
              last_timestamp = log_entry.timestamp if log_entry.timestamp > last_timestamp

              # Callback for new log entry
              yield(:log_entry, log_entry)
            end
          end

          # Process NEW and UPDATED tasks (tasks can appear and change during execution)
          if operation.tasks && block_given?
            operation.tasks.each do |task|
              if processed_task_ids.include?(task.id)
                # Callback for task update (status/progress changes)
                yield(:task_update, task)
              else
                processed_task_ids.add(task.id)
                # Callback for new task
                yield(:task_new, task)
              end
            end
          end

          # Process NEW resources (resources appear as they're created)
          if operation.resources && block_given?
            operation.resources.each do |resource|
              next if processed_resource_ids.include?(resource.id)

              processed_resource_ids.add(resource.id)
              # Callback for new resource
              yield(:resource_new, resource)
            end
          end

          # Status update callback
          yield(:status, operation) if block_given?

          case operation.status
          when 'Completed'
            @logger.info "Operation #{operation_id} completed successfully!"
            return OperationResult.new(operation, self, raw_json)
          when 'Failed'
            @logger.error "Operation #{operation_id} failed: #{operation.status_message}"
            return OperationResult.new(operation, self, raw_json)
          when 'Running', 'Queued'
            elapsed = Time.now - start_time
            if elapsed > timeout
              @logger.error "Operation #{operation_id} timed out after #{timeout} seconds"
              raise Timeout::Error, "Operation #{operation_id} timed out after #{timeout} seconds"
            end

            @logger.debug "Operation #{operation_id} status: #{operation.status} (#{elapsed.round(1)}s elapsed)"
            sleep poll_interval
          else
            @logger.warn "Operation #{operation_id} has unknown status: #{operation.status}"
            return OperationResult.new(operation, self)
          end
        end
      end

      # Validate a catlet configuration using the quick validation endpoint
      # @param config [Hash, String] catlet configuration as Ruby hash or JSON string
      # @return [Object] validation result with is_valid and errors
      # @raise [ProblemDetailsError] if validation fails due to API error
      def validate_catlet_config(config)
        # Convert input to hash if it's a JSON string
        config_hash = case config
                      when String
                        begin
                          JSON.parse(config)
                        rescue JSON::ParserError => e
                          raise ArgumentError, "Invalid JSON string: #{e.message}"
                        end
                      when Hash
                        config
                      else
                        raise ArgumentError, "Config must be a Hash or JSON string, got #{config.class}"
                      end

        # Create the validation request
        request = Eryph::ComputeClient::ValidateConfigRequest.new(configuration: config_hash)

        # Call the validation endpoint
        handle_api_errors do
          catlets.catlets_validate_config(validate_config_request: request)
        end
      end

      # Execute a block and convert ApiError to ProblemDetailsError when appropriate
      # @yield the block to execute
      # @return the result of the block
      # @raise [ProblemDetailsError, Exception] the error with enhanced information
      def handle_api_errors
        yield
      rescue StandardError => e
        # Check if this looks like an API error (has code and response_body)
        raise e unless e.respond_to?(:code) && e.respond_to?(:response_body)

        enhanced_error = ProblemDetailsError.from_api_error(e)
        raise enhanced_error

        # Re-raise non-API errors as-is
      end

      private

      # Search for client ID across all configurations
      # @param reader [ConfigStoresReader] configuration reader
      # @param client_id [String] client ID to find
      # @return [ClientCredentials, nil] credentials if found, nil otherwise
      def find_client_in_any_config(reader, client_id)
        configs = @environment.windows? ? %w[default zero local] : %w[default local]

        configs.each do |config|
          lookup = ClientRuntime::ClientCredentialsLookup.new(reader, config, logger: @logger)
          creds = lookup.get_credentials_by_client_id(client_id, config)
          return creds if creds
        end

        nil
      end

      def default_scopes
        # Default to minimal read-only scope
        %w[compute:read]
      end

      def default_logger
        logger = Logger.new($stdout)
        logger.level = Logger::WARN
        logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity} -- #{progname}: #{msg}\n"
        end
        logger
      end

      def create_api_client(api_name, api_class_name)
        # Try to use the generated API client
        require_relative 'generated'

        # Create the generated API client with our configured API client
        api_client = create_generated_api_client
        api_class = Eryph::ComputeClient.const_get(api_class_name)

        @logger.debug "Creating generated API client for #{api_name} (#{api_class_name})"
        raw_client = api_class.new(api_client)

        # Wrap the API client to handle errors
        ErrorHandlingApiClientWrapper.new(raw_client, self)
      rescue LoadError, NameError => e
        # Generated client must be available - fail fast
        raise ClientRuntime::ConfigurationError,
              "Generated client not available for #{api_name}: #{e.class}: #{e.message}"
      end

      def create_generated_api_client
        # Use the stored compute endpoint
        compute_uri = URI.parse(@compute_endpoint)

        # Create and configure the generated API client
        config = Eryph::ComputeClient::Configuration.new
        # Include port in host if it's not the default port for the scheme
        config.host = if compute_uri.port && compute_uri.port != compute_uri.default_port
                        "#{compute_uri.host}:#{compute_uri.port}"
                      else
                        compute_uri.host
                      end
        config.scheme = compute_uri.scheme
        # Ensure base_path ends with a slash for proper URL construction
        base_path = compute_uri.path.empty? ? '/' : compute_uri.path
        config.base_path = base_path.end_with?('/') ? base_path : "#{base_path}/"

        # Configure SSL settings
        config.ssl_verify = @ssl_config.fetch(:verify_ssl, true)

        # If SSL verification is disabled, set verify_mode to VERIFY_NONE
        if @ssl_config.fetch(:verify_ssl, true) == false
          config.ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
        else
          config.ssl_verify_mode = @ssl_config.fetch(:verify_hostname, true) ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
        end

        config.ssl_ca_file = @ssl_config[:ca_file] if @ssl_config[:ca_file]

        # Create the API client
        api_client = Eryph::ComputeClient::ApiClient.new(config)

        # Configure authentication - the generated client expects bearer token in access_token
        api_client.config.access_token = @token_provider.access_token

        api_client
      end
    end

    # Wrapper for API clients that handles errors and converts them to ProblemDetailsError
    class ErrorHandlingApiClientWrapper
      def initialize(api_client, parent_client)
        @api_client = api_client
        @parent_client = parent_client
      end

      def method_missing(method_name, ...)
        @parent_client.handle_api_errors do
          @api_client.send(method_name, ...)
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @api_client.respond_to?(method_name, include_private)
      end
    end

  end
end
