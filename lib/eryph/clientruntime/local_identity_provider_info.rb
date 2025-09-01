require 'json'
require 'uri'
require 'logger'

module Eryph
  module ClientRuntime
    # Provides information about locally running eryph identity providers
    # Contains decision logic for interpreting identity provider data
    class LocalIdentityProviderInfo
      # @return [Environment] environment abstraction
      attr_reader :environment

      # @return [String] identity provider name
      attr_reader :identity_provider_name

      # @return [Logger] logger instance
      attr_reader :logger

      # Initialize local identity provider info
      # @param environment [Environment] environment abstraction
      # @param identity_provider_name [String] identity provider name
      # @param logger [Logger, nil] logger instance
      def initialize(environment, identity_provider_name = 'identity', logger: nil)
        @environment = environment
        @identity_provider_name = identity_provider_name
        @logger = logger || Logger.new($stdout).tap { |l| l.level = Logger::WARN }
      end

      # Check if the identity provider is running
      # @return [Boolean] true if the identity provider is running
      def running?
        @logger.debug("provider.running?: name=#{@identity_provider_name}")
        
        metadata = get_metadata
        @logger.debug("provider.running?: metadata=#{metadata.empty? ? 'empty' : 'found'}")
        
        return false if metadata.empty?

        process_name = metadata['processName']
        process_id = metadata['processId']
        @logger.debug("provider.running?: process=#{process_name}, pid=#{process_id}")

        if process_name.nil? || process_name.empty? || process_id.nil?
          @logger.debug("provider.running?: invalid process info")
          return false
        end

        # Check if the process is actually running
        is_running = @environment.process_running?(process_id.to_i, process_name)
        @logger.debug("provider.running?: process_check=#{is_running}")
        is_running
      end

      # Get endpoints from the running identity provider
      # @return [Hash] endpoint name -> URI mapping
      def endpoints
        return {} unless running?

        metadata = get_metadata
        endpoints_data = metadata['endpoints']
        return {} unless endpoints_data

        result = {}
        endpoints_data.each do |key, value|
          begin
            uri = URI.parse(value.to_s)
            # Only include valid HTTP/HTTPS URIs
            if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
              result[key] = uri
            end
          rescue URI::InvalidURIError
            # Skip invalid URIs
            next
          end
        end

        result
      end

      # Get the system client private key for eryph-zero
      # @return [String, nil] private key content or nil if not found
      def system_client_private_key
        @logger.debug("system_client_private_key: getting endpoints")
        endpoints_hash = endpoints
        @logger.debug("system_client_private_key: endpoints=#{endpoints_hash.keys.join(',')}")
        
        unless endpoints_hash.key?('identity')
          @logger.debug("system_client_private_key: no identity endpoint")
          return nil
        end

        identity_endpoint = endpoints_hash['identity']&.to_s
        @logger.debug("system_client_private_key: identity_endpoint=#{identity_endpoint}")
        
        private_key = @environment.get_encrypted_system_client(identity_endpoint)
        @logger.debug("system_client_private_key: result=#{private_key ? 'found' : 'nil'}")
        private_key
      end

      # Get system client credentials for eryph-zero
      # @return [Hash, nil] client credentials hash or nil if not available
      def system_client_credentials
        @logger.debug("system_client_credentials: checking endpoints")
        endpoints_hash = endpoints
        @logger.debug("system_client_credentials: endpoints=#{endpoints_hash.keys.join(',')}")
        
        unless endpoints_hash.key?('identity')
          @logger.debug("system_client_credentials: no identity endpoint")
          return nil
        end

        private_key = system_client_private_key
        @logger.debug("system_client_credentials: private_key=#{private_key ? 'found' : 'nil'}")
        return nil unless private_key

        @logger.debug("system_client_credentials: creating credentials hash")
        {
          'id' => 'system-client',
          'name' => 'Eryph Zero System Client',
          'private_key' => private_key,
          'identity_endpoint' => endpoints_hash['identity'].to_s
        }
      end

      private

      def get_metadata
        lock_file_path = File.join(
          @environment.get_application_data_path, 
          @identity_provider_name, 
          '.lock'
        )
        @logger.debug("get_metadata: checking #{lock_file_path}")
        
        unless @environment.file_exists?(lock_file_path)
          @logger.debug("get_metadata: file not found")
          return {}
        end

        begin
          content = @environment.read_file(lock_file_path)
          # Strip BOM if present
          content = content.sub(/\A\xEF\xBB\xBF/, '')
          result = JSON.parse(content)
          @logger.debug("get_metadata: parsed successfully")
          result
        rescue JSON::ParserError => e
          @logger.debug("get_metadata: JSON parse error")
          {}
        rescue IOError => e
          @logger.debug("get_metadata: IO error")
          {}
        end
      end
    end
  end
end