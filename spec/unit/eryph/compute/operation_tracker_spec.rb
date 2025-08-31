require 'spec_helper'

RSpec.describe Eryph::Compute::OperationTracker do
  let(:client) { double('Client') }
  let(:operations_api) { double('OperationsApi') }
  let(:operation_id) { 'test-op-123' }
  let(:test_logger) { TestLogger.new }
  
  subject { described_class.new(client, operation_id) }
  
  before do
    allow(client).to receive(:operations).and_return(operations_api)
    allow(client).to receive(:logger).and_return(test_logger)
    test_logger.clear
    
    # Default stub for any debug_return_type calls that aren't explicitly expected
    allow(operations_api).to receive(:operations_get)
      .with(anything, hash_including(debug_return_type: 'String'))
      .and_return('{}')
  end

  describe '#initialize' do
    it 'creates a new tracker with client and operation ID' do
      tracker = described_class.new(client, operation_id)
      expect(tracker.instance_variable_get(:@client)).to eq(client)
      expect(tracker.instance_variable_get(:@operation_id)).to eq(operation_id)
      expect(tracker.stats[:processed_logs]).to eq(0)
      expect(tracker.stats[:processed_tasks]).to eq(0)
      expect(tracker.stats[:processed_resources]).to eq(0)
    end
  end

  describe 'fluent callback interface' do
    it 'allows chaining callback methods' do
      tracker = subject
        .on_log_entry { |log| }
        .on_task_new { |task| }
        .on_task_update { |task| }
        .on_resource_new { |resource| }
        .on_status_change { |operation| }
      
      expect(tracker).to be_a(described_class)
    end

    it 'stores callbacks correctly' do
      log_callback = ->(log) { }
      task_callback = ->(task) { }
      
      tracker = subject
        .on_log_entry(&log_callback)
        .on_task_new(&task_callback)
      
      callbacks = tracker.instance_variable_get(:@callbacks)
      expect(callbacks[:log_entry]).to eq(log_callback)
      expect(callbacks[:task_new]).to eq(task_callback)
    end
  end

  describe '#track_to_completion' do
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

    context 'when operation completes successfully' do
      it 'returns OperationResult when operation completes' do
        # Mock both calls: debug_return_type for raw JSON, then normal call
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time), debug_return_type: 'String')
          .and_return('{}')
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(completed_operation)
        
        result = subject.track_to_completion(timeout: 10, poll_interval: 1)
        
        expect(result).to be_a(Eryph::Compute::OperationResult)
        expect(result.status).to eq('Completed')
      end
    end

    context 'with log entry callbacks' do
      it 'triggers log entry callbacks for new logs' do
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

        # Mock both calls: debug_return_type for raw JSON, then normal call
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time), debug_return_type: 'String')
          .and_return('{}')
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(operation_with_logs)
        
        received_logs = []
        subject
          .on_log_entry { |log| received_logs << log }
          .track_to_completion(timeout: 10, poll_interval: 1)

        expect(received_logs).to eq([log_entry])
        expect(subject.stats[:processed_logs]).to eq(1)
      end

      it 'does not trigger callbacks for duplicate logs' do
        log1 = double('LogEntry', id: 'log-1', timestamp: Time.now - 10, message: 'First log')
        log2 = double('LogEntry', id: 'log-2', timestamp: Time.now - 5, message: 'Second log')

        first_poll = double('Operation',
          id: operation_id,
          status: 'Running',
          status_message: 'In progress',
          log_entries: [log1],
          tasks: [],
          resources: []
        )

        second_poll = double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          log_entries: [log1, log2], # log1 is duplicate, log2 is new
          tasks: [],
          resources: []
        )

        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(first_poll, second_poll)

        received_logs = []
        subject
          .on_log_entry { |log| received_logs << log }
          .track_to_completion(timeout: 10, poll_interval: 0.1)

        expect(received_logs).to eq([log1, log2])
        expect(subject.stats[:processed_logs]).to eq(2)
      end
    end

    context 'with task callbacks' do
      it 'triggers task_new callback for new tasks' do
        task = double('Task', 
          id: 'task-1', 
          name: 'Test task',
          display_name: 'Test Task',
          progress: 0
        )
        operation_with_tasks = double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          log_entries: [],
          tasks: [task],
          resources: []
        )

        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(operation_with_tasks)
        
        new_tasks = []
        subject
          .on_task_new { |task| new_tasks << task }
          .track_to_completion(timeout: 10, poll_interval: 1)

        expect(new_tasks).to eq([task])
        expect(subject.stats[:processed_tasks]).to eq(1)
      end

      it 'triggers task_update callback for existing tasks' do
        task = double('Task', 
          id: 'task-1', 
          name: 'Test task',
          display_name: 'Test Task',
          progress: 0
        )

        first_poll = double('Operation',
          id: operation_id,
          status: 'Running',
          status_message: 'In progress',
          log_entries: [],
          tasks: [task],
          resources: []
        )

        updated_task = double('Task', 
          id: 'task-1', 
          name: 'Test task',
          display_name: 'Test Task',
          progress: 50
        )

        second_poll = double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          log_entries: [],
          tasks: [updated_task],
          resources: []
        )

        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(first_poll, second_poll)

        new_tasks = []
        updated_tasks = []
        subject
          .on_task_new { |task| new_tasks << task }
          .on_task_update { |task| updated_tasks << task }
          .track_to_completion(timeout: 10, poll_interval: 0.1)

        expect(new_tasks).to eq([task])
        expect(updated_tasks).to include(updated_task)
        expect(subject.stats[:processed_tasks]).to eq(1)
      end
    end

    context 'with resource callbacks' do
      it 'triggers resource_new callback for new resources' do
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

        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(operation_with_resources)
        
        new_resources = []
        subject
          .on_resource_new { |resource| new_resources << resource }
          .track_to_completion(timeout: 10, poll_interval: 1)

        expect(new_resources).to eq([resource])
        expect(subject.stats[:processed_resources]).to eq(1)
      end

      it 'does not trigger callbacks for duplicate resources' do
        resource1 = double('Resource', id: 'resource-1', resource_type: 'Catlet', resource_id: 'cat-1')
        resource2 = double('Resource', id: 'resource-2', resource_type: 'VirtualDisk', resource_id: 'disk-1')

        first_poll = double('Operation',
          id: operation_id,
          status: 'Running',
          status_message: 'In progress',
          log_entries: [],
          tasks: [],
          resources: [resource1]
        )

        second_poll = double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          log_entries: [],
          tasks: [],
          resources: [resource1, resource2] # resource1 is duplicate, resource2 is new
        )

        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(first_poll, second_poll)

        received_resources = []
        subject
          .on_resource_new { |resource| received_resources << resource }
          .track_to_completion(timeout: 10, poll_interval: 0.1)

        expect(received_resources).to eq([resource1, resource2])
        expect(subject.stats[:processed_resources]).to eq(2)
      end
    end

    context 'with status change callbacks' do
      it 'triggers status_change callback on each poll' do
        running_operation = double('Operation',
          id: operation_id,
          status: 'Running',
          status_message: 'In progress',
          log_entries: [],
          tasks: [],
          resources: []
        )

        completed_operation = double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          log_entries: [],
          tasks: [],
          resources: []
        )

        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(running_operation, completed_operation)

        status_changes = []
        subject
          .on_status_change { |operation| status_changes << operation.status }
          .track_to_completion(timeout: 10, poll_interval: 0.1)

        expect(status_changes).to eq(['Running', 'Completed'])
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

      it 'returns OperationResult with failed status' do
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(failed_operation)
        
        result = subject.track_to_completion(timeout: 10, poll_interval: 1)
        
        expect(result).to be_a(Eryph::Compute::OperationResult)
        expect(result.status).to eq('Failed')
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

      it 'raises Timeout::Error when operation exceeds timeout' do
        expect(operations_api).to receive(:operations_get)
          .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
          .and_return(running_operation)
          .at_least(:once)
        
        expect {
          subject.track_to_completion(timeout: 1, poll_interval: 0.1)
        }.to raise_error(Timeout::Error, /Operation #{operation_id} timed out/)
      end
    end
  end

  describe '#stats' do
    it 'returns initial stats with zero counts' do
      stats = subject.stats
      expect(stats).to be_a(Hash)
      expect(stats[:processed_logs]).to eq(0)
      expect(stats[:processed_tasks]).to eq(0)
      expect(stats[:processed_resources]).to eq(0)
    end

    it 'updates stats as items are processed' do
      log_entry = double('LogEntry', id: 'log-1', timestamp: Time.now, message: 'Test log')
      task = double('Task', id: 'task-1', name: 'Test task', display_name: 'Test Task', progress: 0)
      resource = double('Resource', id: 'resource-1', resource_type: 'Catlet', resource_id: 'cat-1')
      
      operation = double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        log_entries: [log_entry],
        tasks: [task],
        resources: [resource]
      )

      expect(operations_api).to receive(:operations_get)
        .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
        .and_return(operation)

      subject.track_to_completion(timeout: 10, poll_interval: 1)
      stats = subject.stats

      expect(stats[:processed_logs]).to eq(1)
      expect(stats[:processed_tasks]).to eq(1)
      expect(stats[:processed_resources]).to eq(1)
    end
  end

  describe 'callback error handling' do
    it 'continues processing even if callbacks raise errors and logs them' do
      log_entry = double('LogEntry', id: 'log-1', timestamp: Time.now, message: 'Test log')
      operation = double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        log_entries: [log_entry],
        tasks: [],
        resources: []
      )

      expect(operations_api).to receive(:operations_get)
        .with(operation_id, expand: 'logs,tasks,resources', log_time_stamp: instance_of(Time))
        .and_return(operation)

      result = subject
        .on_log_entry { |log| raise StandardError, "Test callback error" }
        .track_to_completion(timeout: 10, poll_interval: 1)

      expect(result).to be_a(Eryph::Compute::OperationResult)
      expect(result.status).to eq('Completed')
      
      # Verify that the callback error was logged
      expect(test_logger.logged?(:error, /Error in log_entry callback: Test callback error/)).to be true
    end
  end
end