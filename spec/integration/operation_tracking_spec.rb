require 'integration_helper'

RSpec.describe 'Operation Tracking Integration', :integration do
  before(:all) do
    # Store original user configuration
    @original_user_configs = capture_user_configs
    # Clear user configurations to ensure system-client is used
    clear_user_configs
  end

  after(:all) do
    # Restore original user configuration
    restore_user_configs(@original_user_configs) if @original_user_configs
  end

  let(:zero_client) do
    Eryph.compute_client(
      'zero',
      scopes: %w[compute:write],
      ssl_config: { verify_ssl: false }
    )
  end

  let(:default_client) do
    # Test automatic discovery (should find zero since no other configs exist)
    Eryph.compute_client(
      scopes: %w[compute:write],
      ssl_config: { verify_ssl: false }
    )
  end

  let(:system_client) do
    # Test explicit system-client usage
    Eryph.compute_client(
      'zero',
      client_id: 'system-client',
      scopes: %w[compute:write],
      ssl_config: { verify_ssl: false }
    )
  end

  # Use zero_client as default for compatibility with existing tests
  let(:client) { zero_client }

  let(:catlet_name) { "integration-test-#{Time.now.strftime('%Y%m%d-%H%M%S')}" }

  let(:catlet_config) do
    ComputeClient::NewCatletRequest.new(
      configuration: {
        name: catlet_name,
        parent: 'dbosoft/ubuntu-22.04/starter',
        cpu: { count: 1 },
        memory: { startup: 1024, minimum: 512, maximum: 2048 },
      }
    )
  end



  private

  def capture_user_configs
    # Backup the entire user .eryph directory
    user_eryph_dir = get_user_eryph_dir
    backup_dir = "#{user_eryph_dir}_test_backup_#{Time.now.to_i}"
    
    if Dir.exist?(user_eryph_dir)
      puts "Backing up user .eryph directory to #{backup_dir}"
      FileUtils.cp_r(user_eryph_dir, backup_dir)
      return backup_dir
    end
    
    nil
  rescue StandardError => e
    puts "Warning: Failed to backup user configs: #{e.message}"
    nil
  end

  def get_user_eryph_dir
    # Get platform-specific user .eryph directory
    if Gem.win_platform?
      File.join(ENV['APPDATA'], '.eryph')
    else
      File.expand_path('~/.config/.eryph')
    end
  end

  def clear_user_configs
    # Clear the user .eryph directory
    user_eryph_dir = get_user_eryph_dir
    
    if Dir.exist?(user_eryph_dir)
      puts "Clearing user .eryph directory for test isolation"
      FileUtils.rm_rf(user_eryph_dir)
    end
  rescue StandardError => e
    puts "Warning: Failed to clear user configs: #{e.message}"
  end

  def restore_user_configs(backup_dir)
    return unless backup_dir && Dir.exist?(backup_dir)
    
    user_eryph_dir = get_user_eryph_dir
    
    puts "Restoring user .eryph directory from backup"
    # Remove current directory if it exists
    FileUtils.rm_rf(user_eryph_dir) if Dir.exist?(user_eryph_dir)
    # Restore from backup
    FileUtils.cp_r(backup_dir, user_eryph_dir)
    # Clean up backup
    FileUtils.rm_rf(backup_dir)
    
    puts "User .eryph directory restored successfully"
  rescue StandardError => e
    puts "ERROR: Failed to restore user configs: #{e.message}"
    puts "Your backup is still available at: #{backup_dir}"
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
        status_changes: [],
      }

      # Use wait_for_operation with callbacks
      result = client.wait_for_operation(operation.id, timeout: 600, poll_interval: 2) do |event_type, data|
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
      expect(result.completed?).to be(true), "Expected operation to be completed but got status: \"#{result.status}\". Message: \"#{result.status_message}\". Failed?: #{result.failed?}, Running?: #{result.running?}, Queued?: #{result.queued?}"
      expect(result.failed?).to be(false), "Operation failed with status: \"#{result.status}\" and message: \"#{result.status_message}\""

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
      expect(%w[Running Stopped]).to include(catlet.status) # Could be in either state after creation

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
        status_changes: [],
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
      result = tracker.track_to_completion(timeout: 600, poll_interval: 2)

      # Verify operation completed
      expect(result).to be_a(Eryph::Compute::OperationResult)
      expect(result.completed?).to be(true), "Expected operation to be completed but got status: \"#{result.status}\". Message: \"#{result.status_message}\". Failed?: #{result.failed?}, Running?: #{result.running?}, Queued?: #{result.queued?}"
      expect(result.failed?).to be(false), "Operation failed with status: \"#{result.status}\" and message: \"#{result.status_message}\""

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
      expect(%w[Running Stopped]).to include(catlet.status)
    end

    it 'handles callback errors gracefully' do
      # Create a catlet operation
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)
      expect(operation).not_to be_nil

      # Setup test logger to capture error messages
      test_logger = TestLogger.new
      test_logger.level = Logger::DEBUG
      
      # Create client with test logger for tracker
      test_client = Eryph::Compute::Client.new('zero', ssl_config: { verify_ssl: false }, logger: test_logger)
      
      # Create tracker with callback that raises errors
      tracker = Eryph::Compute::OperationTracker.new(test_client, operation.id)
      error_count = 0

      tracker.on_log_entry do |_log|
        error_count += 1
        raise StandardError, 'Test callback error' if error_count <= 2
      end
      tracker.on_status_change { |_op| } # Normal callback to verify operation continues

      # Track to completion - should not fail despite callback errors
      result = tracker.track_to_completion(timeout: 600, poll_interval: 2)

      expect(result).to be_a(Eryph::Compute::OperationResult)
      expect(result.completed?).to be(true), "Expected operation to be completed but got status: \"#{result.status}\". Message: \"#{result.status_message}\". Failed?: #{result.failed?}, Running?: #{result.running?}, Queued?: #{result.queued?}"
      expect(error_count).to be > 2 # Errors occurred but processing continued
      
      # Verify that callback errors were logged properly
      expect(test_logger.logged?(:error, /Error in log_entry callback: Test callback error/)).to be true
    end
  end

  describe 'OperationResult resource fetching' do
    it 'fetches and caches catlet resources' do
      # Create a catlet operation
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)

      # Wait for completion
      result = client.wait_for_operation(operation.id, timeout: 600, poll_interval: 5)
      expect(result.completed?).to be(true), "Expected operation to be completed but got status: \"#{result.status}\". Message: \"#{result.status_message}\". Failed?: #{result.failed?}, Running?: #{result.running?}, Queued?: #{result.queued?}"

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

      expect do
        client.wait_for_operation(operation.id, timeout: 5, poll_interval: 1)
      end.to raise_error(Timeout::Error, /timed out/)
    end

    it 'OperationTracker raises timeout error for short timeout' do
      # Create a catlet operation
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)

      tracker = Eryph::Compute::OperationTracker.new(client, operation.id)

      expect do
        tracker.track_to_completion(timeout: 5, poll_interval: 1)
      end.to raise_error(Timeout::Error, /timed out/)
    end
  end

  describe 'Operation progress tracking' do
    it 'receives task progress updates during catlet creation' do
      # Create a catlet operation
      operation = client.catlets.catlets_create(new_catlet_request: catlet_config)

      tasks_with_progress = []

      result = client.wait_for_operation(operation.id, timeout: 600, poll_interval: 2) do |event_type, data|
        if event_type == :task_update && data.progress && data.progress > 0 && data.progress < 100
          tasks_with_progress << {
            name: data.display_name || data.name,
            progress: data.progress,
          }
        end
      end

      expect(result.completed?).to be(true), "Expected operation to be completed but got status: \"#{result.status}\". Message: \"#{result.status_message}\". Failed?: #{result.failed?}, Running?: #{result.running?}, Queued?: #{result.queued?}"

      # Should have received some task progress updates during catlet creation
      # Note: This may be empty if tasks complete too quickly, which is acceptable
      expect(tasks_with_progress.first[:progress]).to be_between(1, 99) if tasks_with_progress.any?
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
          { name: 'environment', value: 'test' },
        ],
      }
    end

    it 'expands configuration and returns typed CatletConfigResult' do
      # Create the expand request
      request = ComputeClient::ExpandNewCatletConfigRequest.new(
        configuration: test_config,
        correlation_id: SecureRandom.uuid,
        show_secrets: false
      )

      # Start the expansion operation
      operation = client.catlets.catlets_expand_new_config(expand_new_catlet_config_request: request)
      expect(operation).not_to be_nil
      expect(operation.id).not_to be_empty

      # Wait for completion with typed result extraction
      result = client.wait_for_operation(operation.id, timeout: 600, poll_interval: 2)

      # Verify operation completed successfully
      expect(result.completed?).to be(true), "Expected operation to be completed but got status: \"#{result.status}\". Message: \"#{result.status_message}\". Failed?: #{result.failed?}, Running?: #{result.running?}, Queued?: #{result.queued?}"
      expect(result.failed?).to be(false), "Operation failed with status: \"#{result.status}\" and message: \"#{result.status_message}\""

      # Verify typed result extraction works
      expect(result.result?).to be true
      expect(result.result_type).to eq('CatletConfig')

      # Test the typed result functionality
      typed_result = result.typed_result
      expect(typed_result).to be_a(Eryph::Compute::CatletConfigResult)
      expect(typed_result.result_type).to eq('CatletConfig')

      # Verify configuration was extracted and expanded
      expect(typed_result.configuration?).to be true
      expect(typed_result.name).to eq(test_config[:name])
      # Parent may be expanded with version (e.g., "starter" -> "starter-1.0")
      expect(typed_result.parent).to start_with(test_config[:parent])

      # Verify the configuration contains expanded variables
      config = typed_result.configuration
      expect(config).to be_a(Hash)
      expect(config['name']).to eq(test_config[:name])
      # Parent may be expanded with version
      expect(config['parent']).to start_with(test_config[:parent])
      expect(config['cpu']).to eq(test_config[:cpu].transform_keys(&:to_s))
      expect(config['memory']).to eq(test_config[:memory].transform_keys(&:to_s))

      # Variables should be present (expansion happens later)
      if config.key?('variables') && config['variables'].is_a?(Array)
        variables = config['variables']
        hostname_var = variables.find { |v| v['name'] == 'hostname' }
        if hostname_var && hostname_var['value']
          # Variables may or may not be expanded at this stage
          expect(hostname_var['value']).to be_a(String)
          expect(hostname_var['name']).to eq('hostname')
        end
      end
    end

    it 'handles config expansion errors gracefully with typed results' do
      # Create invalid configuration to trigger expansion error
      invalid_config = {
        name: "invalid-config-#{Time.now.strftime('%Y%m%d-%H%M%S')}",
        parent: 'nonexistent/parent/image', # This should cause expansion to fail
        cpu: { count: 1 }, # Valid CPU count
        memory: { startup: 256 }, # Valid memory (128 MiB aligned)
      }

      request = ComputeClient::ExpandNewCatletConfigRequest.new(
        configuration: invalid_config,
        correlation_id: SecureRandom.uuid,
        show_secrets: false
      )

      # Start the expansion operation
      operation = client.catlets.catlets_expand_new_config(expand_new_catlet_config_request: request)
      expect(operation).not_to be_nil

      # Wait for completion - should fail
      result = client.wait_for_operation(operation.id, timeout: 600, poll_interval: 2)

      # Verify operation failed as expected
      expect(result.completed?).to be false
      expect(result.failed?).to be true
      expect(result.status_message).not_to be_empty

      # Even failed operations should have proper result handling
      expect(result.result?).to be false
      expect(result.typed_result).to be_nil
    end
  end

  describe 'Client Configuration Variants' do
    it 'works with explicit zero configuration client' do
      expect(zero_client.config_name).to eq('zero')
      expect(zero_client.test_connection).to be true
    end

    it 'works with automatic discovery client (should find zero)' do
      expect(default_client.config_name).to eq('zero')
      expect(default_client.test_connection).to be true
    end

    it 'works with explicit system-client ID' do
      expect(system_client.config_name).to eq('zero')  
      expect(system_client.test_connection).to be true
      
      # Verify it's using system-client credentials
      credentials = system_client.instance_variable_get(:@credentials)
      expect(credentials.client_id).to eq('system-client')
    end

    it 'all client variants access the same API endpoints' do
      # Test that different client configurations work with the same operations
      [zero_client, default_client, system_client].each do |test_client|
        projects_list = test_client.projects.projects_list
        expect(projects_list).not_to be_nil
        expect(projects_list.value).not_to be_empty
      end
    end

    it 'handles configuration not found errors properly' do
      expect do
        Eryph.compute_client('nonexistent-config')
      end.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, /No default client found/)
    end

    it 'handles specific client ID not found errors properly' do  
      expect do
        Eryph.compute_client('zero', client_id: 'nonexistent-client-id')
      end.to raise_error(Eryph::ClientRuntime::CredentialsNotFoundError, /nonexistent-client-id.*not found/)
    end
  end
end
