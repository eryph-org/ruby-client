require 'json'
require 'uri'

module Eryph
  module ClientRuntime
    # Provides information about locally running eryph identity providers
    # Contains decision logic for interpreting identity provider data
    class LocalIdentityProviderInfo
      # @return [Environment] environment abstraction
      attr_reader :environment

      # @return [String] identity provider name
      attr_reader :identity_provider_name

      # Initialize local identity provider info
      # @param environment [Environment] environment abstraction
      # @param identity_provider_name [String] identity provider name
      def initialize(environment, identity_provider_name = 'identity')
        @environment = environment
        @identity_provider_name = identity_provider_name
      end

      # Check if the identity provider is running
      # @return [Boolean] true if the identity provider is running
      def running?
        metadata = get_metadata
        return false if metadata.empty?

        process_name = metadata['processName']
        process_id = metadata['processId']

        return false if process_name.nil? || process_name.empty? || process_id.nil?

        # Check if the process is actually running
        @environment.process_running?(process_id.to_i, process_name)
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
        endpoints_hash = endpoints
        return nil unless endpoints_hash.key?('identity')

        identity_endpoint = endpoints_hash['identity']&.to_s
        @environment.get_encrypted_system_client(@identity_provider_name, identity_endpoint)
      end

      # Get system client credentials for eryph-zero
      # @return [Hash, nil] client credentials hash or nil if not available
      def system_client_credentials
        endpoints_hash = endpoints
        return nil unless endpoints_hash.key?('identity')

        private_key = system_client_private_key
        return nil unless private_key

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
        
        return {} unless @environment.file_exists?(lock_file_path)

        begin
          content = @environment.read_file(lock_file_path)
          # Strip BOM if present
          content = content.sub(/\A\xEF\xBB\xBF/, '')
          JSON.parse(content)
        rescue JSON::ParserError, IOError
          {}
        end
      end
    end
  end
end