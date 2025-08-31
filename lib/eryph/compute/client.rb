require 'logger'
require 'set'

module Eryph
  module Compute
    # Main client class for the Eryph Compute API
    # Provides a high-level interface to the compute API with automatic authentication
    class Client
      # @return [String] configuration name used for this client
      attr_reader :config_name

      # @return [String, nil] endpoint name used for lookup
      attr_reader :endpoint_name

      # @return [ClientRuntime::TokenProvider] token provider for authentication
      attr_reader :token_provider

      # @return [Logger] logger instance
      attr_reader :logger

      # Initialize a new compute client using configuration-based credentials
      # @param config_name [String] configuration name
      # @param endpoint_name [String, nil] endpoint name for lookup
      # @param logger [Logger, nil] logger instance
      # @param scopes [Array<String>] OAuth2 scopes
      # @param ssl_config [Hash] SSL configuration options
      # @param environment [ClientRuntime::Environment, nil] environment instance for dependency injection
      # @option ssl_config [Boolean] :verify_ssl (true) whether to verify SSL certificates
      # @option ssl_config [Boolean] :verify_hostname (true) whether to verify hostname
      # @option ssl_config [String] :ca_file path to CA certificate file
      # @option ssl_config [OpenSSL::X509::Certificate] :ca_cert CA certificate object
      def initialize(config_name, endpoint_name: nil, logger: nil, scopes: nil, ssl_config: {}, environment: nil)
        @config_name = config_name
        @endpoint_name = endpoint_name || determine_compute_endpoint_name
        @logger = logger || default_logger
        @ssl_config = ssl_config || {}
        
        # Set up authentication using ClientRuntime
        # For authentication, we always need the identity endpoint
        @credentials_lookup = ClientRuntime.create_credentials_lookup(
          config_name: @config_name, 
          endpoint_name: 'identity',
          environment: environment
        )
        
        credentials = @credentials_lookup.find_credentials
        @token_provider = ClientRuntime::TokenProvider.new(
          credentials,
          scopes: scopes || default_scopes,
          http_config: { logger: @logger }.merge(ssl_config)
        )

        # Generated client is loaded on-demand when individual API clients are created
      end

      # Create a new compute client using explicit credentials
      # @param endpoint [String] compute API endpoint URL
      # @param client_id [String] OAuth2 client ID
      # @param private_key [String, OpenSSL::PKey::RSA] private key for authentication
      # @param logger [Logger, nil] logger instance
      # @param scopes [Array<String>] OAuth2 scopes
      # @return [Client] new client instance
      def self.new_with_credentials(endpoint:, client_id:, private_key:, logger: nil, scopes: nil)
        # Construct token endpoint from compute endpoint
        base_url = endpoint.sub(/\/compute\/?$/, '')
        token_endpoint = "#{base_url}/connect/token"
        
        # Create credentials directly
        credentials = ClientRuntime::ClientCredentials.new(
          client_id: client_id,
          client_name: "Direct Client",
          private_key: private_key,
          token_endpoint: token_endpoint
        )

        # Create instance with explicit credentials
        client = allocate
        client.instance_variable_set(:@config_name, 'direct')
        client.instance_variable_set(:@endpoint_name, 'compute')
        client.instance_variable_set(:@compute_endpoint, endpoint)
        client.instance_variable_set(:@logger, logger || client.send(:default_logger))
        client.instance_variable_set(:@token_provider, ClientRuntime::TokenProvider.new(
          credentials,
          scopes: scopes || client.send(:default_scopes),
          http_config: { logger: client.instance_variable_get(:@logger) }
        ))
        # Generated client is loaded on-demand when individual API clients are created
        client.send(:initialize_instance_variables)
        
        client
      end

      # Test the connection and authentication
      # @return [Boolean] true if connection and authentication work
      def test_connection
        # For now, just test if we can get a token
        token = @token_provider.get_access_token
        !token.nil? && !token.empty?
      rescue => e
        @logger.error "Connection test failed: #{e.message}"
        false
      end

      # Get the current access token
      # @return [String] access token
      def access_token
        @token_provider.get_access_token
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
      # @return [Eryph::ComputeClient::CatletsApi, PlaceholderApiClient] catlets API client
      def catlets
        @catlets ||= create_api_client('catlets', 'CatletsApi')
      end

      # Access the operations API
      # @return [Eryph::ComputeClient::OperationsApi, PlaceholderApiClient] operations API client
      def operations
        @operations ||= create_api_client('operations', 'OperationsApi')
      end

      # Access the projects API
      # @return [Eryph::ComputeClient::ProjectsApi, PlaceholderApiClient] projects API client
      def projects
        @projects ||= create_api_client('projects', 'ProjectsApi')
      end

      # Access the virtual disks API
      # @return [Eryph::ComputeClient::VirtualDisksApi, PlaceholderApiClient] virtual disks API client
      def virtual_disks
        @virtual_disks ||= create_api_client('virtual_disks', 'VirtualDisksApi')
      end

      # Access the virtual networks API
      # @return [Eryph::ComputeClient::VirtualNetworksApi, PlaceholderApiClient] virtual networks API client
      def virtual_networks
        @virtual_networks ||= create_api_client('virtual_networks', 'VirtualNetworksApi')
      end

      # Access the genes API
      # @return [Eryph::ComputeClient::GenesApi, PlaceholderApiClient] genes API client
      def genes
        @genes ||= create_api_client('genes', 'GenesApi')
      end

      # Access the version API
      # @return [Eryph::ComputeClient::VersionApi, PlaceholderApiClient] version API client
      def version
        @version ||= create_api_client('version', 'VersionApi')
      end

      # Get the compute endpoint URL being used by this client
      # @return [String] the compute endpoint URL
      def compute_endpoint_url
        get_compute_endpoint
      rescue => e
        "Error getting endpoint: #{e.message}"
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
      def wait_for_operation(operation_id, timeout: 300, poll_interval: 5, &block)
        @logger.info "Waiting for operation #{operation_id} to complete (timeout: #{timeout}s)..."
        
        start_time = Time.now
        last_timestamp = Time.parse("2018-01-01")
        processed_log_ids = Set.new
        processed_task_ids = Set.new  
        processed_resource_ids = Set.new
        
        loop do
          # Get raw JSON using debug_return_type to work around discriminated union bug
          raw_json = nil
          begin
            raw_json = operations.operations_get(
              operation_id, 
              expand: "logs,tasks,resources",
              log_time_stamp: last_timestamp,
              debug_return_type: 'String'
            )
            @logger.debug "Raw JSON captured: #{raw_json ? 'YES' : 'NO'}"
          rescue => e
            @logger.debug "Failed to capture raw JSON: #{e.message}"
          end
          
          # Get normal deserialized operation
          operation = operations.operations_get(
            operation_id, 
            expand: "logs,tasks,resources", 
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
              if !processed_task_ids.include?(task.id)
                processed_task_ids.add(task.id)
                # Callback for new task
                yield(:task_new, task)
              else
                # Callback for task update (status/progress changes)
                yield(:task_update, task)
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
      def handle_api_errors(&block)
        yield
      rescue => e
        # Check if this looks like an API error (has code and response_body)
        if e.respond_to?(:code) && e.respond_to?(:response_body)
          enhanced_error = ProblemDetailsError.from_api_error(e)
          raise enhanced_error
        else
          # Re-raise non-API errors as-is
          raise e
        end
      end

      private

      def initialize_instance_variables
        # Initialize instance variables for direct credential clients
        # This is called from the self.new_with_credentials method
      end

      def determine_compute_endpoint_name
        # Determine the appropriate endpoint name for compute API lookup
        case @config_name&.downcase
        when 'zero'
          'compute'
        else
          'compute'
        end
      end

      def default_scopes
        # Default to minimal read-only scope
        %w[compute:read]
      end

      def default_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::WARN
        logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity} -- #{progname}: #{msg}\n"
        end
        logger
      end


      def create_api_client(api_name, api_class_name)
        begin
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
          # Fall back to placeholder if generated client is not available
          @logger.warn "Generated client not available for #{api_name}, using placeholder: #{e.class}: #{e.message}"
          PlaceholderApiClient.new(api_name, self)
        end
      end

      def create_generated_api_client
        # Get the compute API endpoint using endpoint lookup
        compute_endpoint = get_compute_endpoint
        compute_uri = URI.parse(compute_endpoint)
        
        # Create and configure the generated API client
        config = Eryph::ComputeClient::Configuration.new
        # Include port in host if it's not the default port for the scheme
        if compute_uri.port && compute_uri.port != compute_uri.default_port
          config.host = "#{compute_uri.host}:#{compute_uri.port}"
        else
          config.host = compute_uri.host
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
        api_client.config.access_token = @token_provider.get_access_token
        
        api_client
      end

      def get_compute_endpoint
        # Reuse the existing credentials lookup's endpoint lookup
        endpoint_lookup = @credentials_lookup.instance_variable_get(:@endpoint_lookup)
        
        # Get the compute endpoint, with fallback to 'compute' if endpoint_name is nil
        endpoint_name = @endpoint_name || 'compute'
        compute_endpoint = endpoint_lookup.get_endpoint(endpoint_name)
        
        unless compute_endpoint
          raise "Compute endpoint '#{endpoint_name}' not found in configuration '#{@config_name}'"
        end
        
        compute_endpoint
      end
    end

    # Wrapper for API clients that handles errors and converts them to ProblemDetailsError
    class ErrorHandlingApiClientWrapper
      def initialize(api_client, parent_client)
        @api_client = api_client
        @parent_client = parent_client
      end
      
      def method_missing(method_name, *args, **kwargs, &block)
        @parent_client.handle_api_errors do
          @api_client.send(method_name, *args, **kwargs, &block)
        end
      end
      
      def respond_to_missing?(method_name, include_private = false)
        @api_client.respond_to?(method_name, include_private)
      end
    end

    # Placeholder API client until generated client is available
    class PlaceholderApiClient
      def initialize(api_name, parent_client)
        @api_name = api_name
        @parent_client = parent_client
      end

      def method_missing(method_name, *args, **kwargs, &block)
        @parent_client.logger.info "#{@api_name.capitalize} API call: #{method_name} (placeholder - requires generated client)"
        
        # Return a simple response structure
        {
          api: @api_name,
          method: method_name,
          args: args,
          kwargs: kwargs,
          message: "This is a placeholder response. Please run the generator script to create the actual API client."
        }
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
end