module Eryph
  module ClientRuntime
    # Looks up endpoint URLs from configuration stores
    # Handles special configurations like 'zero' with local endpoint discovery
    class EndpointLookup
      # @return [ConfigStoresReader] configuration stores reader
      attr_reader :reader

      # @return [String] configuration name
      attr_reader :config_name

      # Initialize endpoint lookup
      # @param reader [ConfigStoresReader] configuration stores reader
      # @param config_name [String] configuration name
      def initialize(reader, config_name)
        @reader = reader
        @config_name = config_name
      end

      # Get an endpoint URL by name
      # @param endpoint_name [String] endpoint name to lookup
      # @return [String, nil] endpoint URL or nil if not found
      def get_endpoint(endpoint_name)
        # First try configuration store endpoints
        store_endpoints = @reader.get_all_endpoints(@config_name)
        endpoint_url = store_endpoints[endpoint_name]
        return endpoint_url if endpoint_url

        # Then try local endpoints for special configurations
        local_endpoints = get_local_endpoints
        local_endpoints[endpoint_name]
      end

      # Get all available endpoints
      # @return [Hash] endpoint name -> URL mapping
      def get_all_endpoints
        store_endpoints = @reader.get_all_endpoints(@config_name)
        local_endpoints = get_local_endpoints

        # Local endpoints have lower priority than store endpoints
        local_endpoints.merge(store_endpoints)
      end

      # Check if an endpoint exists
      # @param endpoint_name [String] endpoint name to check
      # @return [Boolean] true if endpoint exists
      def endpoint_exists?(endpoint_name)
        !get_endpoint(endpoint_name).nil?
      end

      private

      # Get local endpoints for special configurations
      # @return [Hash] endpoint name -> URL mapping
      def get_local_endpoints
        case @config_name.downcase
        when 'zero'
          get_zero_endpoints
        else
          {}
        end
      end

      # Get endpoints for eryph-zero configuration
      # This discovers running eryph-zero instances from runtime lock files
      # @return [Hash] endpoint name -> URL mapping
      def get_zero_endpoints
        require_relative 'local_identity_provider_info'
        
        # Try to discover running identity provider
        provider_info = LocalIdentityProviderInfo.new(@reader.environment, 'zero')
        
        if provider_info.running?
          endpoints_hash = provider_info.endpoints
          
          # Convert URI objects to strings and map to expected names
          result = {}
          endpoints_hash.each do |name, uri|
            case name.downcase
            when 'identity'
              result['identity'] = uri.to_s
            when 'compute'
              result['compute'] = uri.to_s
            else
              # Include other endpoints as-is
              result[name] = uri.to_s
            end
          end
          
          # If we have identity but no compute, derive compute endpoint
          if result['identity'] && !result['compute']
            identity_uri = URI.parse(result['identity'])
            result['compute'] = "#{identity_uri.scheme}://#{identity_uri.host}:#{identity_uri.port}/compute"
          end
          
          return result
        end

        # Fallback to common local endpoints if no runtime info found
        fallback_zero_endpoints
      end

      # Fallback endpoint discovery for eryph-zero when runtime file is not available
      # @return [Hash] endpoint name -> URL mapping
      def fallback_zero_endpoints
        endpoints = {}

        # Try common local endpoints for eryph-zero
        zero_candidates = [
          'https://localhost:8080',
          'https://127.0.0.1:8080',
          'http://localhost:8080',
          'http://127.0.0.1:8080'
        ]

        zero_candidates.each do |candidate_url|
          if test_zero_endpoint(candidate_url)
            endpoints['identity'] = candidate_url
            endpoints['compute'] = "#{candidate_url}/compute"
            break
          end
        end

        endpoints
      end

      # Test if a URL hosts an eryph-zero instance
      # @param base_url [String] base URL to test
      # @return [Boolean] true if eryph-zero is detected
      def test_zero_endpoint(base_url)
        # This is a simplified test - in a full implementation you might:
        # 1. Make an HTTP request to check for eryph-zero health endpoint
        # 2. Check for specific response headers or content
        # 3. Verify SSL certificates if applicable
        
        # For now, we'll just check if the URL format is valid
        begin
          uri = URI.parse(base_url)
          # Check if scheme, host, and explicit port are present
          has_scheme = !uri.scheme.nil?
          has_host = !uri.host.nil? && !uri.host.empty?
          has_explicit_port = base_url.include?(':') && base_url.match(/:(\d+)/)
          
          !!(has_scheme && has_host && has_explicit_port)
        rescue URI::InvalidURIError
          false
        end
      end
    end
  end
end