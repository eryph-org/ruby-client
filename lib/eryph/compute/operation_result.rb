require 'cgi'
require 'json'

module Eryph
  module Compute
    # Typed result for CatletConfig operations
    CatletConfigResult = Struct.new(:result_type, :configuration, keyword_init: true) do
      def self.from_raw_json(raw_json)
        parsed = JSON.parse(raw_json)
        new(
          result_type: 'CatletConfig',
          configuration: parsed.dig('result', 'configuration')
        )
      rescue JSON::ParserError
        new(result_type: 'CatletConfig', configuration: nil)
      end
      
      # Convenience methods
      def has_configuration?
        !configuration.nil?
      end
      
      def name
        configuration['name'] if configuration
      end
      
      def parent
        configuration['parent'] if configuration
      end
    end

    # Wrapper class for operation results that provides convenient access 
    # to operation state and resources
    class OperationResult
      attr_reader :operation, :client
      
      def initialize(operation, client, raw_operation_json = nil)
        @operation = operation
        @client = client
        @fetched_resources = {}
        @cached_collections = {}
        @raw_operation_json = raw_operation_json # Cache the raw JSON if provided
      end
      
      def id
        @operation.id
      end
      
      def status
        @operation.status
      end
      
      def completed?
        @operation.status == 'Completed'
      end
      
      def failed?
        @operation.status == 'Failed'
      end
      
      def running?
        @operation.status == 'Running'
      end
      
      def queued?
        @operation.status == 'Queued'
      end
      
      def status_message
        @operation.status_message
      end
      
      # Get the raw resource references from the operation
      def resources
        @operation.resources || []
      end
      
      # Get the raw tasks from the operation
      def tasks
        @operation.tasks || []
      end
      
      # Get the raw log entries from the operation
      def log_entries
        @operation.log_entries || []
      end
      
      # Get the raw operation result object
      # @return [Object, nil] the raw result object from the operation
      def result
        @operation.result
      end
      
      # Check if the operation has a result
      # @return [Boolean] true if the operation has a result
      def has_result?
        !@operation.result.nil?
      end
      
      # Get the result type discriminator
      # @return [String, nil] the result type or nil if no result
      def result_type
        return nil unless has_result?
        @operation.result.result_type
      end
      
      # Get typed result based on result_type
      # @return [Struct, nil] typed result or nil
      def typed_result
        return @typed_result if defined?(@typed_result)
        
        return nil unless has_result?
        
        @typed_result = case result_type
        when 'CatletConfig'
          if @raw_operation_json
            @client.logger.info "Creating typed CatletConfigResult from raw JSON"
            CatletConfigResult.from_raw_json(@raw_operation_json)
          else
            @client.logger.warn "No raw JSON available for typed result creation"
            CatletConfigResult.new(result_type: 'CatletConfig', configuration: nil)
          end
        else
          @client.logger.warn "Unknown operation result type: #{result_type}" if result_type
          nil
        end
      end
      
      # Fetch actual resource objects (lazy loading with caching)
      # @return [Array] array of fetched resource objects
      def fetch_resources
        resources.map do |resource|
          fetch_resource(resource)
        end.compact
      end
      
      # Fetch a specific resource by its reference
      # @param resource_ref [Object] the resource reference from operation.resources
      # @return [Object, nil] the fetched resource object or nil if failed
      def fetch_resource(resource_ref)
        cache_key = "#{resource_ref.resource_type}:#{resource_ref.resource_id}"
        
        return @fetched_resources[cache_key] if @fetched_resources.key?(cache_key)
        
        @fetched_resources[cache_key] = begin
          case resource_ref.resource_type
          when 'Catlet'
            @client.catlets.catlets_get(resource_ref.resource_id)
          when 'VirtualDisk'
            @client.virtual_disks.virtual_disks_get(resource_ref.resource_id)
          when 'VirtualNetwork'
            @client.virtual_networks.virtual_networks_get(resource_ref.resource_id)
          when 'Project'
            @client.projects.projects_get(resource_ref.resource_id)
          else
            @client.logger.warn "Unknown resource type: #{resource_ref.resource_type}"
            nil
          end
        rescue => e
          @client.logger.error "Error fetching #{resource_ref.resource_type.downcase} #{resource_ref.resource_id}: #{e.message}"
          nil
        end
      end
      
      # Find raw resource references by type
      # @param type [String] the resource type to filter by
      # @return [Array] array of resource references
      def find_resources_by_type(type)
        resources.select { |r| r.resource_type == type }
      end
      
      # Get all catlet objects created by this operation
      # @return [Array] array of catlet objects
      def catlets
        @cached_collections[:catlets] ||= find_resources_by_type('Catlet').map { |r| fetch_resource(r) }.compact
      end
      
      # Get all virtual disk objects created by this operation
      # @return [Array] array of virtual disk objects
      def virtual_disks
        @cached_collections[:virtual_disks] ||= find_resources_by_type('VirtualDisk').map { |r| fetch_resource(r) }.compact
      end
      
      # Get all virtual network objects created by this operation
      # @return [Array] array of virtual network objects
      def virtual_networks
        @cached_collections[:virtual_networks] ||= find_resources_by_type('VirtualNetwork').map { |r| fetch_resource(r) }.compact
      end
      
      # Get all project objects created by this operation
      # @return [Array] array of project objects
      def projects_from_resources
        @cached_collections[:projects] ||= find_resources_by_type('Project').map { |r| fetch_resource(r) }.compact
      end
      
      # Get the first catlet if this operation created one
      # @return [Object, nil] the first catlet or nil
      def catlet
        catlets.first
      end
      
      # Get the first virtual disk if this operation created one
      # @return [Object, nil] the first virtual disk or nil
      def virtual_disk
        virtual_disks.first
      end
      
      # Get the first virtual network if this operation created one
      # @return [Object, nil] the first virtual network or nil
      def virtual_network
        virtual_networks.first
      end
      
      # Get operation summary with counts and resource type breakdown
      # @return [Hash] summary hash with operation details
      def summary
        resource_counts = Hash.new(0)
        resources.each do |resource|
          resource_counts[resource.resource_type] += 1
        end
        
        {
          operation_id: id,
          status: status,
          status_message: status_message,
          log_entries_count: log_entries.size,
          tasks_count: tasks.size,
          resources_count: resources.size,
          resource_types: resource_counts,
          has_result: has_result?,
          result_type: result_type
        }
      end
      
      # String representation
      def to_s
        "#<OperationResult id=#{id} status=#{status} resources=#{resources.size}>"
      end
      
      def inspect
        to_s
      end
    end
  end
end