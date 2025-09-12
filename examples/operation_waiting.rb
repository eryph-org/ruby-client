#!/usr/bin/env ruby

# Operation Waiting Example
# Demonstrates different approaches to waiting for operations to complete

require_relative '../lib/eryph'

def main
  puts 'Operation Waiting Example'
  puts '-' * 25

  client = create_client

  operation_id = create_test_operation(client)
  return unless operation_id

  demonstrate_waiting_approaches(client, operation_id)
end

def create_client
  puts 'Creating compute client...'

  client = Eryph.compute_client(ssl_config: { verify_ssl: false }, scopes: ['compute:write'])
  
  # Test connection to ensure proper token setup
  unless client.test_connection
    puts 'Connection test failed'
    exit 1
  end
  
  client
end

def create_test_operation(client)
  puts 'Creating test operation (catlet creation)...'

  config = {
    name: "wait-demo-#{Time.now.to_i}",
    parent: 'dbosoft/ubuntu-22.04/starter',
    cpu: { count: 1 },
    memory: { startup: 1024 },
  }

  request = Eryph::ComputeClient::NewCatletRequest.new(configuration: config)
  operation = client.catlets.catlets_create(new_catlet_request: request)

  puts "Test operation created: #{operation.id}"
  puts "Initial status: #{operation.status}"
  operation.id
rescue StandardError => e
  puts "Failed to create test operation: #{e.message}"
  nil
end

def demonstrate_waiting_approaches(client, operation_id)
  puts "\nDemonstrating wait_for_operation with callbacks:"

  # Approach 1: Basic wait_for_operation with callbacks
  result1 = demonstrate_callback_wait(client, operation_id)

  # Clean up the test catlet if successful
  cleanup_test_catlet(client, result1) if result1
end

def demonstrate_callback_wait(client, operation_id)
  puts "Tracking operation with wait_for_operation callbacks...\n"
  
  log_count = 0
  task_count = 0
  resource_count = 0
  start_time = Time.now

  operation = client.wait_for_operation(operation_id, timeout: 600) do |event_type, data|
    case event_type
    when :log_entry
      log_count += 1
      timestamp = data.timestamp.strftime('%H:%M:%S.%3N') rescue data.timestamp.to_s
      puts "📝 [#{timestamp}] #{data.message}"
    when :task_new
      task_count += 1
      puts "🔧 TASK: #{data.name} started"
    when :task_update
      status_icon = data.status == 'Running' ? '⚡' : 
                   data.status == 'Completed' ? '✅' : 
                   data.status == 'Failed' ? '❌' : '⏸️'
      puts "#{status_icon} TASK: #{data.name} -> #{data.status}"
    when :resource_new
      resource_count += 1
      puts "📦 RESOURCE: #{data.resource_type} (#{data.resource_id})"
    when :status
      elapsed = Time.now - start_time
      puts "🔄 Operation status: #{data.status} (#{elapsed.round(1)}s elapsed)"
    end
  end

  elapsed = Time.now - start_time
  puts "\n✅ Operation completed in #{elapsed.round(2)}s"
  puts "   Logs: #{log_count}, Tasks: #{task_count}, Resources: #{resource_count}"
  
  operation
rescue StandardError => e
  puts "❌ Operation failed: #{e.message}"
  nil
end

def cleanup_test_catlet(client, operation_result)
  unless operation_result
    puts "\n⚠️  No operation result - cannot cleanup test catlet"
    return
  end

  # Extract catlet ID from the operation result  
  catlet_id = nil
  if operation_result.respond_to?(:resources) && operation_result.resources&.any?
    catlet_resource = operation_result.resources.find { |r| r.resource_type == 'Catlet' }
    catlet_id = catlet_resource.resource_id if catlet_resource
  end

  unless catlet_id
    puts "\n⚠️  Could not find catlet ID in operation result - cannot cleanup"
    return
  end

  puts "\nCleaning up test catlet: #{catlet_id}"
  
  begin
    operation = client.catlets.catlets_delete(catlet_id)
    puts "Deletion initiated (Operation: #{operation.id})"
    
    # Simple wait for cleanup
    client.wait_for_operation(operation.id, timeout: 60)
    puts "✅ Test catlet cleaned up successfully"
  rescue StandardError => e
    puts "⚠️  Warning: Could not delete test catlet: #{e.message}"
  end
end

begin
  main
  puts "\nOperation waiting example completed"
rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts "Credentials not found: #{e.message}"
  puts 'Please configure eryph-zero or set up client credentials'
  exit 1
rescue Eryph::ClientRuntime::TokenRequestError => e
  puts "Authentication failed: #{e.message}"
  exit 1
rescue Eryph::Compute::ApiError => e
  puts "API Error: #{e.message}"
  exit 1
rescue StandardError => e
  puts "Unexpected error: #{e.message}"
  puts e.backtrace if ENV['DEBUG']
  exit 1
end