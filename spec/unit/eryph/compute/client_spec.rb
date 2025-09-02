require 'spec_helper'

RSpec.describe Eryph::Compute::Client do
  let(:config_name) { 'test' }
  let(:credentials) { build(:credentials, configuration: config_name) }
  let(:mock_reader) { double('ConfigStoresReader') }
  let(:mock_environment) { double('Environment') }
  let(:credentials_lookup) { double('CredentialsLookup', find_credentials: credentials) }
  let(:test_logger) { TestLogger.new }

  before do
    # Mock the internal credential discovery
    allow(Eryph::ClientRuntime::ConfigStoresReader).to receive(:new).and_return(mock_reader)
    allow(Eryph::ClientRuntime::ClientCredentialsLookup).to receive(:new).and_return(credentials_lookup)
    allow(Eryph::ClientRuntime::EndpointLookup).to receive(:new).and_return(double('EndpointLookup', endpoint: 'https://test.eryph.local/compute'))
    allow(mock_reader).to receive(:environment).and_return(mock_environment)
    allow(mock_environment).to receive(:windows?).and_return(true)
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

  describe '.new with client_id' do
    let(:client_id) { 'specific-client' }
    let(:specific_credentials) { build(:credentials, client_id: client_id) }

    before do
      allow(credentials_lookup).to receive(:get_credentials_by_client_id).and_return(specific_credentials)
    end

    it 'creates a client with specific client ID' do
      client = described_class.new(config_name, client_id: client_id)

      expect(client).to be_a(described_class)
      expect(client.token_provider).to be_a(Eryph::ClientRuntime::TokenProvider)
    end
  end

  describe '.new with both config_name and client_id (specific client in specific config)' do
    let(:client_id) { 'specific-client' }
    let(:specific_credentials) { build(:credentials, client_id: client_id, configuration: config_name) }
    let(:mock_lookup) { double('ClientCredentialsLookup') }

    before do
      allow(Eryph::ClientRuntime::ClientCredentialsLookup).to receive(:new).and_return(mock_lookup)
    end

    it 'finds specific client in specific config without fallback' do
      expect(mock_lookup).to receive(:get_credentials_by_client_id)
        .with(client_id, config_name)
        .and_return(specific_credentials)

      client = described_class.new(config_name, client_id: client_id)
      expect(client).to be_a(described_class)
    end

    it 'raises error when specific client not found in specific config' do
      expect(mock_lookup).to receive(:get_credentials_by_client_id)
        .with(client_id, config_name)
        .and_return(nil)

      expect do
        described_class.new(config_name, client_id: client_id)
      end.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, /Client 'specific-client' not found in configuration 'test'/)
    end
  end

  describe '.new with client_id only (search across configs)' do
    let(:client_id) { 'cross-config-client' }
    let(:found_credentials) { build(:credentials, client_id: client_id, configuration: 'found-config') }

    it 'finds client across multiple configs' do
      # Mock the private method directly
      allow_any_instance_of(described_class).to receive(:find_client_in_any_config)
        .with(anything, client_id)
        .and_return(found_credentials)

      client = described_class.new(nil, client_id: client_id)
      expect(client).to be_a(described_class)
    end

    it 'raises error when client not found in any config' do
      allow_any_instance_of(described_class).to receive(:find_client_in_any_config)
        .with(anything, client_id)
        .and_return(nil)

      expect do
        described_class.new(nil, client_id: client_id)
      end.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, /not found in any configuration/)
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
               resources: [])
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
                           message: 'Test log message')
        operation_with_logs = double('Operation',
                                     id: operation_id,
                                     status: 'Completed',
                                     status_message: 'Success',
                                     log_entries: [log_entry],
                                     tasks: [],
                                     resources: [])

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
                      progress: 50)
        operation_with_tasks = double('Operation',
                                      id: operation_id,
                                      status: 'Completed',
                                      status_message: 'Success',
                                      log_entries: [],
                                      tasks: [task],
                                      resources: [])

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
                          resource_id: 'catlet-123')
        operation_with_resources = double('Operation',
                                          id: operation_id,
                                          status: 'Completed',
                                          status_message: 'Success',
                                          log_entries: [],
                                          tasks: [],
                                          resources: [resource])

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
               resources: [])
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
               resources: [])
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

        expect do
          client.wait_for_operation(operation_id, timeout: 1, poll_interval: 0.1)
        end.to raise_error(Timeout::Error, /Operation #{operation_id} timed out/)

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
                            resources: [])

        second_poll = double('Operation',
                             id: operation_id,
                             status: 'Running',
                             status_message: 'In progress',
                             log_entries: [log1, log2], # log1 should be skipped, log2 is new
                             tasks: [task1], # task1 should trigger task_update
                             resources: [resource1]) # resource1 is new

        final_poll = double('Operation',
                            id: operation_id,
                            status: 'Completed',
                            status_message: 'Success',
                            log_entries: [log1, log2],
                            tasks: [task1],
                            resources: [resource1])

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
        log_events = callback_events.select { |event_type, _data| event_type == :log_entry }
        task_new_events = callback_events.select { |event_type, _data| event_type == :task_new }
        task_update_events = callback_events.select { |event_type, _data| event_type == :task_update }
        resource_events = callback_events.select { |event_type, _data| event_type == :resource_new }

        expect(log_events.map(&:last)).to match_array(%w[log-1 log-2])
        expect(task_new_events.map(&:last)).to eq(['task-1'])
        expect(task_update_events.map(&:last)).to include('task-1') # At least one update
        expect(resource_events.map(&:last)).to eq(['resource-1'])
      end
    end
  end

  describe '#test_connection' do
    let(:mock_token_provider) { double('TokenProvider') }
    let(:client) do
      # Mock TokenProvider during construction
      allow(Eryph::ClientRuntime::TokenProvider).to receive(:new).and_return(mock_token_provider)
      described_class.new(config_name, logger: test_logger)
    end

    before do
      test_logger.clear
    end

    it 'returns true when token can be obtained' do
      allow(mock_token_provider).to receive(:ensure_access_token).and_return('valid-token')

      result = client.test_connection
      expect(result).to be true
    end

    it 'returns false when token is nil' do
      allow(mock_token_provider).to receive(:ensure_access_token).and_return(nil)

      result = client.test_connection
      expect(result).to be false
    end

    it 'returns false when token is empty' do
      allow(mock_token_provider).to receive(:ensure_access_token).and_return('')

      result = client.test_connection
      expect(result).to be false
    end

    it 'returns false and logs error when exception occurs' do
      allow(mock_token_provider).to receive(:ensure_access_token).and_raise(StandardError, 'Token error')

      result = client.test_connection
      expect(result).to be false
      expect(test_logger.logged?(:error, /Connection test failed: Token error/)).to be true
    end
  end

  describe 'token operations' do
    let(:mock_token_provider) { double('TokenProvider') }
    let(:client) do
      # Mock TokenProvider during construction
      allow(Eryph::ClientRuntime::TokenProvider).to receive(:new).and_return(mock_token_provider)
      described_class.new(config_name)
    end


    describe '#refresh_token' do
      it 'delegates to token provider' do
        expect(mock_token_provider).to receive(:refresh_token).and_return('new-token')

        result = client.refresh_token
        expect(result).to eq('new-token')
      end
    end

    describe '#authorization_header' do
      it 'delegates to token provider' do
        expect(mock_token_provider).to receive(:authorization_header).and_return('Bearer test-token')

        result = client.authorization_header
        expect(result).to eq('Bearer test-token')
      end
    end
  end

  describe 'API client getters' do
    let(:client) { described_class.new(config_name) }

    before do
      # Mock the create_api_client method to return a placeholder
      allow(client).to receive(:create_api_client).and_return(double('ApiClient'))
    end

    describe '#catlets' do
      it 'creates and caches catlets API client' do
        expect(client).to receive(:create_api_client).with('catlets', 'CatletsApi').once.and_return('catlets_api')

        # First call creates
        result1 = client.catlets
        expect(result1).to eq('catlets_api')

        # Second call uses cache
        result2 = client.catlets
        expect(result2).to eq('catlets_api')
      end
    end

    describe '#operations' do
      it 'creates and caches operations API client' do
        expect(client).to receive(:create_api_client).with('operations', 'OperationsApi').once.and_return('operations_api')

        result1 = client.operations
        expect(result1).to eq('operations_api')

        result2 = client.operations
        expect(result2).to eq('operations_api')
      end
    end

    describe '#projects' do
      it 'creates and caches projects API client' do
        expect(client).to receive(:create_api_client).with('projects', 'ProjectsApi').once.and_return('projects_api')

        result = client.projects
        expect(result).to eq('projects_api')
      end
    end

    describe '#virtual_disks' do
      it 'creates and caches virtual disks API client' do
        expect(client).to receive(:create_api_client).with('virtual_disks', 'VirtualDisksApi').once.and_return('vdisks_api')

        result = client.virtual_disks
        expect(result).to eq('vdisks_api')
      end
    end

    describe '#virtual_networks' do
      it 'creates and caches virtual networks API client' do
        expect(client).to receive(:create_api_client).with('virtual_networks', 'VirtualNetworksApi').once.and_return('vnetworks_api')

        result = client.virtual_networks
        expect(result).to eq('vnetworks_api')
      end
    end

    describe '#genes' do
      it 'creates and caches genes API client' do
        expect(client).to receive(:create_api_client).with('genes', 'GenesApi').once.and_return('genes_api')

        result = client.genes
        expect(result).to eq('genes_api')
      end
    end

    describe '#version' do
      it 'creates and caches version API client' do
        expect(client).to receive(:create_api_client).with('version', 'VersionApi').once.and_return('version_api')

        result = client.version
        expect(result).to eq('version_api')
      end
    end
  end

  describe '#compute_endpoint_url' do
    let(:client) { described_class.new(config_name) }

    it 'returns the compute endpoint URL' do
      # The endpoint is set during initialization, so we can test it directly
      result = client.compute_endpoint_url
      expect(result).to eq('https://test.eryph.local/compute')
    end
  end

  describe '#validate_catlet_config' do
    let(:client) { described_class.new(config_name) }
    let(:mock_catlets_api) { double('CatletsApi') }
    let(:validation_result) { double('ValidationResult', is_valid: true, errors: []) }

    before do
      allow(client).to receive(:catlets).and_return(mock_catlets_api)
      allow(client).to receive(:handle_api_errors).and_yield.and_return(validation_result)
    end

    it 'validates hash configuration' do
      config_hash = { 'name' => 'test-catlet', 'parent' => 'ubuntu' }
      request_double = double('Request')

      expect(Eryph::ComputeClient::ValidateConfigRequest).to receive(:new)
        .with(configuration: config_hash)
        .and_return(request_double)

      expect(mock_catlets_api).to receive(:catlets_validate_config)
        .with(validate_config_request: request_double)
        .and_return(validation_result)

      result = client.validate_catlet_config(config_hash)
      expect(result).to eq(validation_result)
    end

    it 'validates JSON string configuration' do
      json_string = '{"name":"test-catlet","parent":"ubuntu"}'
      expected_hash = { 'name' => 'test-catlet', 'parent' => 'ubuntu' }
      request_double = double('Request')

      expect(Eryph::ComputeClient::ValidateConfigRequest).to receive(:new)
        .with(configuration: expected_hash)
        .and_return(request_double)

      expect(mock_catlets_api).to receive(:catlets_validate_config)
        .with(validate_config_request: request_double)
        .and_return(validation_result)

      result = client.validate_catlet_config(json_string)
      expect(result).to eq(validation_result)
    end

    it 'raises error for invalid JSON' do
      invalid_json = '{"invalid": json}'

      expect do
        client.validate_catlet_config(invalid_json)
      end.to raise_error(ArgumentError, /Invalid JSON string/)
    end

    it 'raises error for invalid input type' do
      expect do
        client.validate_catlet_config(123)
      end.to raise_error(ArgumentError, /Config must be a Hash or JSON string/)
    end
  end

  describe '#handle_api_errors' do
    let(:client) { described_class.new(config_name) }

    it 'returns block result when no errors occur' do
      result = client.send(:handle_api_errors) { 'success' }
      expect(result).to eq('success')
    end

    it 'enhances API errors with ProblemDetailsError' do
      # Create a custom error class that responds to code and response_body
      api_error_class = Class.new(StandardError) do
        attr_reader :code, :response_body

        def initialize(message, code = nil, response_body = nil)
          super(message)
          @code = code
          @response_body = response_body
        end
      end

      api_error = api_error_class.new('API Error', 400, '{"title":"Bad Request"}')
      enhanced_error = StandardError.new('Enhanced error') # Use StandardError to avoid ProblemDetailsError issues

      expect(Eryph::Compute::ProblemDetailsError).to receive(:from_api_error)
        .with(api_error)
        .and_return(enhanced_error)

      expect do
        client.send(:handle_api_errors) { raise api_error }
      end.to raise_error(enhanced_error)
    end

    it 're-raises non-API errors as-is' do
      standard_error = StandardError.new('generic error')

      expect do
        client.send(:handle_api_errors) { raise standard_error }
      end.to raise_error(standard_error)
    end
  end

  describe 'fallback behavior when generated client unavailable' do
    let(:client) { described_class.new(config_name) }

    it 'creates placeholder API clients when generated client fails to load' do
      # Mock the create_api_client method to return PlaceholderApiClient directly
      allow(client).to receive(:create_api_client) do |api_name, _api_class_name|
        Eryph::Compute::PlaceholderApiClient.new(api_name, client)
      end

      catlets_client = client.catlets
      expect(catlets_client.class.name).to eq('Eryph::Compute::PlaceholderApiClient')
    end

    it 'creates placeholder API clients when generated classes unavailable' do
      # Mock the create_api_client method to return PlaceholderApiClient directly
      allow(client).to receive(:create_api_client) do |api_name, _api_class_name|
        Eryph::Compute::PlaceholderApiClient.new(api_name, client)
      end

      catlets_client = client.catlets
      expect(catlets_client.class.name).to eq('Eryph::Compute::PlaceholderApiClient')
    end
  end

  describe 'default logger creation' do
    it 'creates default logger when none provided' do
      client = described_class.new(config_name, logger: nil)

      # Access the logger to ensure default was created
      logger = client.instance_variable_get(:@logger)
      expect(logger).to be_a(Logger)
      expect(logger.level).to eq(Logger::WARN)
    end
  end

  describe 'SSL configuration' do
    let(:client) { described_class.new(config_name, ssl_config: ssl_config) }
    let(:ssl_config) { { verify_ssl: false, verify_hostname: false } }

    it 'applies SSL configuration to generated API client' do
      # Test that SSL config is properly applied
      expect(client.instance_variable_get(:@ssl_config)).to eq(ssl_config)
    end
  end
end
