require 'logger'

module Eryph
  module ClientRuntime
    # Looks up endpoint URLs from configuration stores
    # Handles special configurations like 'zero' with local endpoint discovery
    class EndpointLookup
      # @return [ConfigStoresReader] configuration stores reader
      attr_reader :reader

      # @return [String] configuration name
      attr_reader :config_name

      # @return [Logger] logger instance
      attr_reader :logger

      # Initialize endpoint lookup
      # @param reader [ConfigStoresReader] configuration stores reader
      # @param config_name [String] configuration name
      # @param logger [Logger, nil] logger instance
      def initialize(reader, config_name, logger: nil)
        @reader = reader
        @config_name = config_name
        @logger = logger || Logger.new($stdout).tap { |l| l.level = Logger::WARN }
      end

      # Get an endpoint URL by name
      # @param endpoint_name [String] endpoint name to lookup
      # @return [String, nil] endpoint URL or nil if not found
      def endpoint(endpoint_name)
        @logger.debug("get_endpoint: looking for '#{endpoint_name}' in config '#{@config_name}'")

        # First try configuration store endpoints
        store_endpoints = @reader.get_all_endpoints(@config_name)
        @logger.debug("get_endpoint: store_endpoints count=#{store_endpoints.length}")

        endpoint_url = store_endpoints[endpoint_name]
        if endpoint_url
          @logger.debug("get_endpoint: found in config store=#{endpoint_url}")
          return endpoint_url
        end

        # Then try local endpoints for special configurations
        local_eps = local_endpoints
        @logger.debug("get_endpoint: local_endpoints count=#{local_eps.length}")

        endpoint_url = local_eps[endpoint_name]
        if endpoint_url
          @logger.debug("get_endpoint: found in local endpoints=#{endpoint_url}")
        else
          @logger.debug('get_endpoint: not found anywhere')
        end

        endpoint_url
      end

      # Get all available endpoints
      # @return [Hash] endpoint name -> URL mapping
      def all_endpoints
        store_endpoints = @reader.get_all_endpoints(@config_name)
        local_eps = local_endpoints

        # Local endpoints have lower priority than store endpoints
        local_eps.merge(store_endpoints)
      end

      # Check if an endpoint exists
      # @param endpoint_name [String] endpoint name to check
      # @return [Boolean] true if endpoint exists
      def endpoint_exists?(endpoint_name)
        !endpoint(endpoint_name).nil?
      end

      private

      # Get local endpoints for special configurations
      # @return [Hash] endpoint name -> URL mapping
      def local_endpoints
        @logger.debug("get_local_endpoints: config=#{@config_name}")

        case @config_name&.downcase
        when 'zero'
          @logger.debug('get_local_endpoints: checking zero config')
          zero_endpoints
        when 'local'
          @logger.debug('get_local_endpoints: checking local config')
          get_local_endpoints_for_config('local')
        else
          @logger.debug('get_local_endpoints: no special config, returning empty')
          {}
        end
      end

      # Get endpoints for eryph-zero configuration
      # This discovers running eryph-zero instances from runtime lock files
      # @return [Hash] endpoint name -> URL mapping
      def zero_endpoints
        require_relative 'local_identity_provider_info'

        # Try to discover running identity provider
        provider_info = LocalIdentityProviderInfo.new(@reader.environment, 'zero', logger: @logger)

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

        # No fallback - if runtime info not found, return empty hash
        {}
      end


      # Get endpoints for eryph-local configuration
      # This discovers running eryph-local instances from runtime lock files
      # @return [Hash] endpoint name -> URL mapping
      def get_local_endpoints_for_config(config_name)
        require_relative 'local_identity_provider_info'

        # Try to discover running identity provider
        provider_info = LocalIdentityProviderInfo.new(@reader.environment, config_name, logger: @logger)

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

        # No fallback for local config - if not running, return empty
        {}
      end

    end
  end
end
