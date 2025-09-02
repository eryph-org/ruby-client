require 'set'

module Eryph
  module Compute
    # Advanced operation tracker with fluent callback registration
    # Provides more control over operation tracking than the basic wait_for_operation
    class OperationTracker
      attr_reader :operation_id, :client

      def initialize(client, operation_id)
        @client = client
        @operation_id = operation_id
        @processed_log_ids = Set.new
        @processed_task_ids = Set.new
        @processed_resource_ids = Set.new
        @last_timestamp = Time.parse('2018-01-01')
        @callbacks = {}
        @raw_json = nil
      end

      # Register callback for new log entries
      # @yield [log_entry] callback for each new log entry
      # @return [self] for method chaining
      def on_log_entry(&block)
        @callbacks[:log_entry] = block
        self
      end

      # Register callback for new tasks
      # @yield [task] callback for each new task discovered
      # @return [self] for method chaining
      def on_task_new(&block)
        @callbacks[:task_new] = block
        self
      end

      # Register callback for task updates (status/progress changes)
      # @yield [task] callback for each task update
      # @return [self] for method chaining
      def on_task_update(&block)
        @callbacks[:task_update] = block
        self
      end

      # Register callback for new resources
      # @yield [resource] callback for each new resource discovered
      # @return [self] for method chaining
      def on_resource_new(&block)
        @callbacks[:resource_new] = block
        self
      end

      # Register callback for status changes
      # @yield [operation] callback for each status update
      # @return [self] for method chaining
      def on_status_change(&block)
        @callbacks[:status_change] = block
        self
      end

      # Single poll to check current state without blocking
      # @return [Operation] the current operation state
      def poll
        # Get raw JSON using debug_return_type (same approach as Client)
        begin
          @raw_json = @client.operations.operations_get(
            @operation_id,
            expand: 'logs,tasks,resources',
            log_time_stamp: @last_timestamp,
            debug_return_type: 'String'
          )
          @client.logger.debug "Raw JSON captured: #{@raw_json ? 'YES' : 'NO'}"
        rescue StandardError => e
          @client.logger.debug "Failed to capture raw JSON: #{e.message}"
        end

        # Get the normal deserialized operation
        operation = @client.operations.operations_get(
          @operation_id,
          expand: 'logs,tasks,resources',
          log_time_stamp: @last_timestamp
        )

        process_updates(operation)
        operation
      end

      # Track operation until completion with polling
      # @param timeout [Integer] timeout in seconds (default: 300)
      # @param poll_interval [Integer] polling interval in seconds (default: 5)
      # @return [OperationResult] the completed operation result
      # @raise [Timeout::Error] if the operation times out
      def track_to_completion(timeout: 300, poll_interval: 5)
        start_time = Time.now

        @client.logger.info "Tracking operation #{@operation_id} to completion (timeout: #{timeout}s)..."

        loop do
          operation = poll

          if operation.status == 'Completed'
            @client.logger.info "Operation #{@operation_id} completed successfully!"
            @client.logger.info "Raw JSON available: #{@raw_json ? 'YES' : 'NO'}"
            @client.logger.info "Raw JSON length: #{@raw_json ? @raw_json.length : 'N/A'}"
            return OperationResult.new(operation, @client, @raw_json)
          elsif operation.status == 'Failed'
            @client.logger.error "Operation #{@operation_id} failed: #{operation.status_message}"
            @client.logger.info "Raw JSON available: #{@raw_json ? 'YES' : 'NO'}"
            return OperationResult.new(operation, @client, @raw_json)
          end

          elapsed = Time.now - start_time
          if elapsed > timeout
            @client.logger.error "Operation #{@operation_id} timed out after #{timeout} seconds"
            raise Timeout::Error, "Operation #{@operation_id} timed out after #{timeout} seconds"
          end

          @client.logger.debug "Operation #{@operation_id} status: #{operation.status} (#{elapsed.round(1)}s elapsed)"
          sleep poll_interval
        end
      end

      # Track with a single callback function (like wait_for_operation)
      # @param timeout [Integer] timeout in seconds
      # @param poll_interval [Integer] polling interval in seconds
      # @yield [event_type, data] callback for operation events
      # @return [OperationResult] the completed operation result
      def track(timeout: 300, poll_interval: 5)
        if block_given?
          # Set up temporary callback
          original_callbacks = @callbacks.dup

          @callbacks[:log_entry] = ->(data) { yield(:log_entry, data) }
          @callbacks[:task_new] = ->(data) { yield(:task_new, data) }
          @callbacks[:task_update] = ->(data) { yield(:task_update, data) }
          @callbacks[:resource_new] = ->(data) { yield(:resource_new, data) }
          @callbacks[:status_change] = ->(data) { yield(:status, data) }

          begin
            result = track_to_completion(timeout: timeout, poll_interval: poll_interval)
          ensure
            # Restore original callbacks
            @callbacks = original_callbacks
          end

          result
        else
          track_to_completion(timeout: timeout, poll_interval: poll_interval)
        end
      end

      # Get current operation state without updating tracking state
      # @return [Operation] the current operation
      def current_state
        @client.operations.operations_get(@operation_id)
      end

      # Reset tracking state (clears processed IDs and timestamp)
      # @return [self] for method chaining
      def reset_state
        @processed_log_ids.clear
        @processed_task_ids.clear
        @processed_resource_ids.clear
        @last_timestamp = Time.parse('2018-01-01')
        self
      end

      # Get statistics about what has been processed so far
      # @return [Hash] statistics hash
      def stats
        {
          operation_id: @operation_id,
          processed_logs: @processed_log_ids.size,
          processed_tasks: @processed_task_ids.size,
          processed_resources: @processed_resource_ids.size,
          last_timestamp: @last_timestamp,
        }
      end

      # String representation
      def to_s
        "#<OperationTracker operation_id=#{@operation_id} stats=#{stats}>"
      end

      def inspect
        to_s
      end

      private

      # Process updates from a polled operation
      # @param operation [Operation] the operation to process
      def process_updates(operation)
        # Process new logs
        operation.log_entries&.each do |log_entry|
          next if @processed_log_ids.include?(log_entry.id)

          @processed_log_ids.add(log_entry.id)
          @last_timestamp = log_entry.timestamp if log_entry.timestamp > @last_timestamp

          begin
            @callbacks[:log_entry]&.call(log_entry)
          rescue StandardError => e
            @client.logger.error "Error in log_entry callback: #{e.message}"
          end
        end

        # Process new and updated tasks
        operation.tasks&.each do |task|
          if @processed_task_ids.include?(task.id)
            begin
              @callbacks[:task_update]&.call(task)
            rescue StandardError => e
              @client.logger.error "Error in task_update callback: #{e.message}"
            end
          else
            @processed_task_ids.add(task.id)
            begin
              @callbacks[:task_new]&.call(task)
            rescue StandardError => e
              @client.logger.error "Error in task_new callback: #{e.message}"
            end
          end
        end

        # Process new resources
        operation.resources&.each do |resource|
          next if @processed_resource_ids.include?(resource.id)

          @processed_resource_ids.add(resource.id)
          begin
            @callbacks[:resource_new]&.call(resource)
          rescue StandardError => e
            @client.logger.error "Error in resource_new callback: #{e.message}"
          end
        end

        # Status update
        begin
          @callbacks[:status_change]&.call(operation)
        rescue StandardError => e
          @client.logger.error "Error in status_change callback: #{e.message}"
        end
      end
    end
  end
end
