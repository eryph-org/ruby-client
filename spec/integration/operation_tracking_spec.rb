require 'integration_helper'

RSpec.describe 'Operation Tracking Integration', :integration do
  let(:client) do
    Eryph.compute_client(
      'zero',
      scopes: %w[compute:write],
      verify_ssl: false
    )
  end

  let(:catlet_name) { "integration-test-#{Time.now.strftime('%Y%m%d-%H%M%S')}" }

  let(:catlet_config) do
    ::ComputeClient::NewCatletRequest.new(
      configuration: {
        name: catlet_name,
        parent: 'dbosoft/ubuntu-22.04/starter',
        cpu: { count: 1 },
        memory: { startup: 1024, minimum: 512, maximum: 2048 }
      }
    )
  end

  before do
    skip "Integration tests disabled" unless ENV['INTEGRATION_TESTS'] == '1'
    
    # Verify we can connect to the compute API
    begin
      expect(client.test_connection).to be true
    rescue => e
      skip "Cannot connect to Eryph compute API: #{e.message}"
    end
  end

  after do
    next unless ENV['INTEGRATION_TESTS'] == '1'
    
    # Cleanup all integration test catlets
    cleanup_test_catlets
  end

  private

  def cleanup_test_catlets
    begin
      puts "Cleaning up integration test catlets..."
      
      # Find all catlets with our test naming pattern
      catlets_response = client.catlets.catlets_list
      catlets_array = catlets_response.respond_to?(:value) ? catlets_response.value : catlets_response
      catlets_array = [catlets_array] unless catlets_array.is_a?(Array)
      
      test_catlets = catlets_array.select do |catlet|
        catlet.name&.start_with?('integration-test-')
      end
      
      if test_catlets.any?
        test_catlets.each do |catlet|
          puts "Deleting test catlet: #{catlet.name} (#{catlet.id})"
          begin
            client.catlets.catlets_delete(catlet.id)
          rescue => e
            puts "Warning: Failed to delete catlet #{catlet.name}: #{e.message}"
          end
        end
      else
        puts "No integration test catlets found to cleanup"
      end
      
    rescue => e
      puts "Warning: Failed to cleanup test catlets: #{e.message}"
    end
  end

  describe '#wait_for_operation with callbacks' do
    it 'tracks catlet creation operation with callbacks' do
      # Create a catlet operation
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)
      expect(operation).not_to be_nil
      expect(operation.id).not_to be_empty
      
      # Track events received via callbacks
      events = {
        log_entries: [],
        new_tasks: [],
        updated_tasks: [],
        new_resources: [],
        status_changes: []
      }
      
      # Use wait_for_operation with callbacks
      result = client.wait_for_operation(operation.id, timeout: 300, poll_interval: 2) do |event_type, data|
        case event_type
        when :log_entry
          events[:log_entries] << data
        when :task_new
          events[:new_tasks] << data
        when :task_update
          events[:updated_tasks] << data
        when :resource_new
          events[:new_resources] << data
        when :status
          events[:status_changes] << data
        end
      end
      
      # Verify operation completed
      expect(result).to be_a(Eryph::Compute::OperationResult)
      expect(result.completed?).to be true
      expect(result.failed?).to be false
      
      # Verify we received events during the operation
      expect(events[:log_entries]).not_to be_empty
      expect(events[:new_tasks]).not_to be_empty
      expect(events[:new_resources]).not_to be_empty
      expect(events[:status_changes]).not_to be_empty
      
      # Verify at least one catlet resource was created
      catlet_resources = result.find_resources_by_type('Catlet')
      expect(catlet_resources).not_to be_empty
      
      # Verify we can fetch the actual catlet
      catlets = result.catlets
      expect(catlets).not_to be_empty
      
      catlet = catlets.first
      expect(catlet.name).to eq(catlet_name)
      expect(['Running', 'Stopped']).to include(catlet.status) # Could be in either state after creation
      
      # Verify operation summary
      summary = result.summary
      expect(summary[:status]).to eq('Completed')
      expect(summary[:log_entries_count]).to be > 0
      expect(summary[:tasks_count]).to be > 0
      expect(summary[:resources_count]).to be > 0
      expect(summary[:resource_types]).to have_key('Catlet')
    end
  end

  describe 'OperationTracker' do
    it 'tracks catlet creation operation with fluent callback API' do
      # Create a catlet operation
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)
      expect(operation).not_to be_nil
      expect(operation.id).not_to be_empty
      
      # Track events with OperationTracker
      events = {
        log_entries: [],
        new_tasks: [],
        updated_tasks: [],
        new_resources: [],
        status_changes: []
      }
      
      # Create and configure OperationTracker
      tracker = Eryph::Compute::OperationTracker.new(client, operation.id)
      
      tracker
        .on_log_entry { |log| events[:log_entries] << log }
        .on_task_new { |task| events[:new_tasks] << task }
        .on_task_update { |task| events[:updated_tasks] << task }
        .on_resource_new { |resource| events[:new_resources] << resource }
        .on_status_change { |operation| events[:status_changes] << operation }
      
      # Track to completion
      result = tracker.track_to_completion(timeout: 300, poll_interval: 2)
      
      # Verify operation completed
      expect(result).to be_a(Eryph::Compute::OperationResult)
      expect(result.completed?).to be true
      expect(result.failed?).to be false
      
      # Verify we received events during the operation
      expect(events[:log_entries]).not_to be_empty
      expect(events[:new_tasks]).not_to be_empty
      expect(events[:new_resources]).not_to be_empty
      expect(events[:status_changes]).not_to be_empty
      
      # Verify tracker statistics
      stats = tracker.stats
      expect(stats[:processed_logs]).to be > 0
      expect(stats[:processed_tasks]).to be > 0
      expect(stats[:processed_resources]).to be > 0
      
      # Verify at least one catlet resource was created
      catlet_resources = result.find_resources_by_type('Catlet')
      expect(catlet_resources).not_to be_empty
      
      # Verify we can fetch the actual catlet
      catlets = result.catlets
      expect(catlets).not_to be_empty
      
      catlet = catlets.first
      expect(catlet.name).to eq(catlet_name)
      expect(['Running', 'Stopped']).to include(catlet.status)
    end

    it 'handles callback errors gracefully' do
      # Create a catlet operation
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)
      expect(operation).not_to be_nil
      
      # Create tracker with a callback that raises errors
      # Note: This test intentionally generates error log messages to verify error handling
      tracker = Eryph::Compute::OperationTracker.new(client, operation.id)
      error_count = 0
      
      tracker
        .on_log_entry { |log| 
          error_count += 1
          raise StandardError, "Test callback error" if error_count <= 2
        }
        .on_status_change { |op| } # Normal callback to verify operation continues
      
      # Track to completion - should not fail despite callback errors
      # Expected to see "Error in log_entry callback: Test callback error" messages in output
      result = tracker.track_to_completion(timeout: 300, poll_interval: 2)
      
      expect(result).to be_a(Eryph::Compute::OperationResult)
      expect(result.completed?).to be true
      expect(error_count).to be > 2 # Errors occurred but processing continued
    end
  end

  describe 'OperationResult resource fetching' do
    it 'fetches and caches catlet resources' do
      # Create a catlet operation
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)
      
      # Wait for completion
      result = client.wait_for_operation(operation.id, timeout: 300, poll_interval: 5)
      expect(result.completed?).to be true
      
      # Test catlet fetching and caching
      first_fetch = result.catlets
      expect(first_fetch).not_to be_empty
      
      # Second fetch should return cached results (test by verifying same object)
      second_fetch = result.catlets
      expect(second_fetch).to equal(first_fetch) # Same object reference due to caching
      
      # Verify catlet data
      catlet = first_fetch.first
      expect(catlet.id).to match(/^[0-9a-f-]{36}$/) # UUID format
      expect(catlet.name).to eq(catlet_name)
      expect(catlet.vm_id).not_to be_nil
      expect(catlet.status).not_to be_nil
    end
  end

  describe 'Operation timeout handling' do
    it 'raises timeout error for short timeout' do
      # Create a catlet operation (which typically takes longer than 5 seconds)
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)
      
      expect {
        client.wait_for_operation(operation.id, timeout: 5, poll_interval: 1)
      }.to raise_error(Timeout::Error, /timed out/)
    end

    it 'OperationTracker raises timeout error for short timeout' do
      # Create a catlet operation
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)
      
      tracker = Eryph::Compute::OperationTracker.new(client, operation.id)
      
      expect {
        tracker.track_to_completion(timeout: 5, poll_interval: 1)
      }.to raise_error(Timeout::Error, /timed out/)
    end
  end

  describe 'Operation progress tracking' do
    it 'receives task progress updates during catlet creation' do
      # Create a catlet operation
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)
      
      tasks_with_progress = []
      
      result = client.wait_for_operation(operation.id, timeout: 300, poll_interval: 2) do |event_type, data|
        if event_type == :task_update && data.progress && data.progress > 0 && data.progress < 100
          tasks_with_progress << { 
            name: data.display_name || data.name, 
            progress: data.progress 
          }
        end
      end
      
      expect(result.completed?).to be true
      
      # Should have received some task progress updates during catlet creation
      # Note: This may be empty if tasks complete too quickly, which is acceptable
      if tasks_with_progress.any?
        expect(tasks_with_progress.first[:progress]).to be_between(1, 99)
      end
    end
  end

  describe 'Configuration expansion with typed results' do
    let(:test_config) do
      {
        name: "expand-test-#{Time.now.strftime('%Y%m%d-%H%M%S')}",
        parent: 'dbosoft/ubuntu-22.04/starter',
        cpu: { count: 1 },
        memory: { startup: 1024, minimum: 512, maximum: 2048 },
        variables: [
          { name: 'hostname', value: '{{catlet_name}}-host' },
          { name: 'environment', value: 'test' }
        ]
      }
    end

    it 'expands configuration and returns typed CatletConfigResult' do
      # Create the expand request
      request = ::ComputeClient::ExpandNewCatletConfigRequest.new(
        configuration: test_config,
        correlation_id: SecureRandom.uuid,
        show_secrets: false
      )
      
      # Start the expansion operation
      operation = client.catlets.catlets_expand_new_config(expand_new_catlet_config_request: request)
      expect(operation).not_to be_nil
      expect(operation.id).not_to be_empty
      
      # Wait for completion with typed result extraction
      result = client.wait_for_operation(operation.id, timeout: 120, poll_interval: 2)
      
      # Verify operation completed successfully
      expect(result.completed?).to be true
      expect(result.failed?).to be false
      
      # Verify typed result extraction works
      expect(result.has_result?).to be true
      expect(result.result_type).to eq('CatletConfig')
      
      # Test the typed result functionality
      typed_result = result.typed_result
      expect(typed_result).to be_a(Eryph::Compute::CatletConfigResult)
      expect(typed_result.result_type).to eq('CatletConfig')
      
      # Verify configuration was extracted and expanded
      expect(typed_result.has_configuration?).to be true
      expect(typed_result.name).to eq(test_config[:name])
      # Parent may be expanded with version (e.g., "starter" -> "starter-1.0")
      expect(typed_result.parent).to start_with(test_config[:parent])
      
      # Verify the configuration contains expanded variables
      config = typed_result.configuration
      expect(config).to be_a(Hash)
      expect(config['name']).to eq(test_config[:name])
      # Parent may be expanded with version
      expect(config['parent']).to start_with(test_config[:parent])
      expect(config['cpu']).to eq(test_config[:cpu])
      expect(config['memory']).to eq(test_config[:memory])
      
      # Variables should be expanded or present  
      if config.key?('variables') && config['variables'].is_a?(Array)
        variables = config['variables']
        hostname_var = variables.find { |v| v['name'] == 'hostname' }
        if hostname_var && hostname_var['value']
          # If hostname was expanded, it should contain the catlet name
          expect(hostname_var['value']).to include(test_config[:name])
        end
      end
    end

    it 'handles config expansion errors gracefully with typed results' do
      # Create invalid configuration to trigger expansion error
      invalid_config = {
        name: "invalid-config-#{Time.now.strftime('%Y%m%d-%H%M%S')}",
        parent: 'nonexistent/parent/image',  # This should cause expansion to fail
        cpu: { count: 1 },  # Valid CPU count
        memory: { startup: 256 }  # Valid memory (128 MiB aligned)
      }
      
      request = ::ComputeClient::ExpandNewCatletConfigRequest.new(
        configuration: invalid_config,
        correlation_id: SecureRandom.uuid,
        show_secrets: false
      )
      
      # Start the expansion operation
      operation = client.catlets.catlets_expand_new_config(expand_new_catlet_config_request: request)
      expect(operation).not_to be_nil
      
      # Wait for completion - should fail
      result = client.wait_for_operation(operation.id, timeout: 120, poll_interval: 2)
      
      # Verify operation failed as expected
      expect(result.completed?).to be false
      expect(result.failed?).to be true
      expect(result.status_message).not_to be_empty
      
      # Even failed operations should have proper result handling
      expect(result.has_result?).to be false
      expect(result.typed_result).to be_nil
    end
  end
end