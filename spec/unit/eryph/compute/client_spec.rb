require 'spec_helper'

RSpec.describe Eryph::Compute::Client do
  let(:config_name) { 'test' }
  let(:credentials) { build(:credentials) }
  let(:credentials_lookup) { double('CredentialsLookup', find_credentials: credentials) }
  let(:test_logger) { TestLogger.new }
  
  before do
    allow(Eryph::ClientRuntime).to receive(:create_credentials_lookup).and_return(credentials_lookup)
  end
  
  describe '.new' do
    it 'creates a client with configuration' do
      client = described_class.new(config_name)
      expect(client.config_name).to eq(config_name)
      expect(client.token_provider).to be_a(Eryph::ClientRuntime::TokenProvider)
    end
    
    it 'uses default scopes' do
      client = described_class.new(config_name)
      expect(client.token_provider.scopes).to include('compute:read')
    end
  end
  
  describe '.new_with_credentials' do
    let(:endpoint) { 'https://test.eryph.local/compute' }
    let(:client_id) { 'test-client' }
    let(:private_key) { OpenSSL::PKey::RSA.generate(2048) }
    
    it 'creates a client with explicit credentials' do
      client = described_class.new_with_credentials(
        endpoint: endpoint,
        client_id: client_id,
        private_key: private_key
      )
      
      expect(client).to be_a(described_class)
      expect(client.token_provider).to be_a(Eryph::ClientRuntime::TokenProvider)
    end
  end

  describe '#wait_for_operation' do
    let(:client) { described_class.new(config_name, logger: test_logger) }
    let(:operation_id) { 'test-op-123' }
    let(:operations_api) { double('OperationsApi') }
    
    before do
      allow(client).to receive(:operations).and_return(operations_api)
      test_logger.clear
    end

    context 'when operation completes successfully' do
      let(:completed_operation) do
        double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          log_entries: [],
          tasks: [],
          resources: []
        )
      end

      it 'returns OperationResult when operation completes and logs success' do
        # Expect two calls: one for raw JSON, one for deserialized operation
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time), debug_return_type: 'String')
          .and_return('{}')
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(completed_operation)
        
        result = client.wait_for_operation(operation_id, timeout: 10, poll_interval: 1)
        
        expect(result).to be_a(Eryph::Compute::OperationResult)
        expect(result.status).to eq('Completed')
        
        # Verify that the success was logged
        expect(test_logger.logged?(:info, /Operation #{operation_id} completed successfully/)).to be true
      end

      it 'processes log entries via callback' do
        log_entry = double('LogEntry', 
          id: 'log-1', 
          timestamp: Time.now, 
          message: 'Test log message'
        )
        operation_with_logs = double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          log_entries: [log_entry],
          tasks: [],
          resources: []
        )

        # Expect two calls: one for raw JSON, one for deserialized operation
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time), debug_return_type: 'String')
          .and_return('{}')
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(operation_with_logs)
        
        callback_events = []
        client.wait_for_operation(operation_id, timeout: 10, poll_interval: 1) do |event_type, data|
          callback_events << [event_type, data]
        end

        expect(callback_events).to include([:log_entry, log_entry])
        expect(callback_events).to include([:status, operation_with_logs])
      end

      it 'processes new tasks via callback' do
        task = double('Task', 
          id: 'task-1', 
          name: 'Test task',
          display_name: 'Test Task',
          progress: 50
        )
        operation_with_tasks = double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          log_entries: [],
          tasks: [task],
          resources: []
        )

        # Expect two calls: one for raw JSON, one for deserialized operation
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time), debug_return_type: 'String')
          .and_return('{}')
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(operation_with_tasks)
        
        callback_events = []
        client.wait_for_operation(operation_id, timeout: 10, poll_interval: 1) do |event_type, data|
          callback_events << [event_type, data]
        end

        expect(callback_events).to include([:task_new, task])
        expect(callback_events).to include([:status, operation_with_tasks])
      end

      it 'processes new resources via callback' do
        resource = double('Resource', 
          id: 'resource-1', 
          resource_type: 'Catlet',
          resource_id: 'catlet-123'
        )
        operation_with_resources = double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          log_entries: [],
          tasks: [],
          resources: [resource]
        )

        # Expect two calls: one for raw JSON, one for deserialized operation
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time), debug_return_type: 'String')
          .and_return('{}')
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(operation_with_resources)
        
        callback_events = []
        client.wait_for_operation(operation_id, timeout: 10, poll_interval: 1) do |event_type, data|
          callback_events << [event_type, data]
        end

        expect(callback_events).to include([:resource_new, resource])
        expect(callback_events).to include([:status, operation_with_resources])
      end
    end

    context 'when operation fails' do
      let(:failed_operation) do
        double('Operation',
          id: operation_id,
          status: 'Failed',
          status_message: 'Operation failed',
          log_entries: [],
          tasks: [],
          resources: []
        )
      end

      it 'returns OperationResult with failed status and logs error' do
        # Expect two calls: one for raw JSON, one for deserialized operation
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time), debug_return_type: 'String')
          .and_return('{}')
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(failed_operation)
        
        result = client.wait_for_operation(operation_id, timeout: 10, poll_interval: 1)
        
        expect(result).to be_a(Eryph::Compute::OperationResult)
        expect(result.status).to eq('Failed')
        
        # Verify that the failure was logged
        expect(test_logger.logged?(:error, /Operation #{operation_id} failed/)).to be true
      end
    end

    context 'when operation times out' do
      let(:running_operation) do
        double('Operation',
          id: operation_id,
          status: 'Running',
          status_message: 'In progress',
          log_entries: [],
          tasks: [],
          resources: []
        )
      end

      it 'raises Timeout::Error when operation exceeds timeout and logs error' do
        # Expect multiple calls for timeout test
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time), debug_return_type: 'String')
          .and_return('{}')
          .at_least(:once)
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(running_operation)
          .at_least(:once)
        
        expect {
          client.wait_for_operation(operation_id, timeout: 1, poll_interval: 0.1)
        }.to raise_error(Timeout::Error, /Operation #{operation_id} timed out/)
        
        # Verify that the timeout was logged
        expect(test_logger.logged?(:error, /Operation #{operation_id} timed out after 1 seconds/)).to be true
      end
    end

    context 'with progressive operation updates' do
      it 'tracks and avoids duplicate processing of log entries, tasks, and resources' do
        log1 = double('LogEntry', id: 'log-1', timestamp: Time.now - 10, message: 'First log')
        log2 = double('LogEntry', id: 'log-2', timestamp: Time.now - 5, message: 'Second log')
        task1 = double('Task', id: 'task-1', name: 'Task 1', display_name: 'Task 1', progress: 0)
        resource1 = double('Resource', id: 'resource-1', resource_type: 'Catlet', resource_id: 'cat-1')

        first_poll = double('Operation',
          id: operation_id,
          status: 'Running',
          status_message: 'In progress',
          log_entries: [log1],
          tasks: [task1],
          resources: []
        )

        second_poll = double('Operation',
          id: operation_id,
          status: 'Running', 
          status_message: 'In progress',
          log_entries: [log1, log2], # log1 should be skipped, log2 is new
          tasks: [task1], # task1 should trigger task_update
          resources: [resource1] # resource1 is new
        )

        final_poll = double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          log_entries: [log1, log2],
          tasks: [task1],
          resources: [resource1]
        )

        # Expect multiple calls for progressive updates test
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time), debug_return_type: 'String')
          .and_return('{}', '{}', '{}')
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(first_poll, second_poll, final_poll)

        callback_events = []
        client.wait_for_operation(operation_id, timeout: 10, poll_interval: 0.1) do |event_type, data|
          callback_events << [event_type, data.respond_to?(:id) ? data.id : data.status]
        end

        # Verify we get the expected sequence without duplicates
        log_events = callback_events.select { |event, _| event == :log_entry }
        task_new_events = callback_events.select { |event, _| event == :task_new }
        task_update_events = callback_events.select { |event, _| event == :task_update }
        resource_events = callback_events.select { |event, _| event == :resource_new }

        expect(log_events.map(&:last)).to match_array(['log-1', 'log-2'])
        expect(task_new_events.map(&:last)).to eq(['task-1']) 
        expect(task_update_events.map(&:last)).to include('task-1') # At least one update
        expect(resource_events.map(&:last)).to eq(['resource-1'])
      end
    end
  end
end