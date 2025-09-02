#!/usr/bin/env ruby

# Operation Tracking Example  
# Demonstrates the advanced OperationTracker class with fluent callback API

require_relative '../lib/eryph'
require 'time'

CATLET_NAME = "tracking-demo-#{Time.now.strftime('%Y%m%d-%H%M%S')}"

def main
  puts 'Eryph Ruby Client - OperationTracker Example'
  puts '=' * 45

  client = create_client

  operation_id = start_test_operation(client)
  return unless operation_id

  result = demonstrate_operation_tracker(client, operation_id)
  cleanup_test_catlet(client, result)
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

def start_test_operation(client)
  puts "\nCreating catlet: #{CATLET_NAME}"
  puts 'This will create a test operation to demonstrate tracking...'

  config = {
    name: CATLET_NAME,
    parent: 'dbosoft/ubuntu-22.04/starter',
    cpu: { count: 1 },
    memory: { startup: 1024 },
  }

  request = Eryph::ComputeClient::NewCatletRequest.new(configuration: config)
  operation = client.catlets.catlets_create(new_catlet_request: request)

  puts "Operation initiated: #{operation.id}"
  puts "Initial status: #{operation.status}"
  puts

  operation.id
rescue StandardError => e
  puts "Failed to start test operation: #{e.message}"
  nil
end

def demonstrate_operation_tracker(client, operation_id)
  puts "Tracking operation with OperationTracker class..."
  puts "(Press Ctrl+C to interrupt)"
  puts

  # Track counters for display
  log_count = 0
  task_count = 0
  resource_count = 0
  status_updates = 0
  start_time = Time.now

  begin
    # Create OperationTracker with fluent callback interface
    tracker = Eryph::Compute::OperationTracker.new(client, operation_id)
    
    tracker
      .on_log_entry do |log_entry|
        log_count += 1
        timestamp = format_timestamp(log_entry.timestamp)
        puts "📝 [#{timestamp}] LOG: #{log_entry.message}"
      end
      .on_task_new do |task|
        task_count += 1
        puts "🔧 TASK ADDED: #{task.name} (#{task.id})"
      end
      .on_task_update do |task|
        status_icon = task.status == 'Running' ? '⚡' : 
                     task.status == 'Completed' ? '✅' : 
                     task.status == 'Failed' ? '❌' : '⏸️'
        puts "#{status_icon} TASK UPDATE: #{task.name} -> #{task.status}"
      end
      .on_resource_new do |resource|
        resource_count += 1
        puts "📦 RESOURCE ADDED: #{resource.resource_type} (#{resource.resource_id})"
      end
      .on_status_change do |operation|
        status_updates += 1
        elapsed = Time.now - start_time
        status_icon = operation.status == 'Running' ? '⚡' : 
                     operation.status == 'Completed' ? '✅' : 
                     operation.status == 'Failed' ? '❌' : '⏸️'
        puts "#{status_icon} STATUS: #{operation.status} (#{format_duration(elapsed)})"
      end
    
    # Start tracking (this will block until operation completes)
    puts "Starting operation tracking..."
    puts
    result = tracker.track_to_completion(timeout: 600)
    
    # Display final result
    elapsed = Time.now - start_time
    if result.status == 'Completed'
      puts
      puts "🎉 Operation completed successfully in #{format_duration(elapsed)}"
      puts "   Final status: #{result.status}"
    else
      puts
      puts "💥 Operation failed after #{format_duration(elapsed)}"
      puts "   Final status: #{result.status}"
      puts "   Error: #{result.status_message}" if result.respond_to?(:status_message)
    end
    
    puts
    display_tracking_summary(log_count, task_count, resource_count, status_updates)
    
    result
  rescue Interrupt
    puts "\nTracking interrupted by user"
    elapsed = Time.now - start_time
    puts "Tracked for #{format_duration(elapsed)}"
    display_tracking_summary(log_count, task_count, resource_count, status_updates)
    nil
  rescue StandardError => e
    puts "Error during tracking: #{e.message}"
    nil
  end
end

def format_timestamp(timestamp)
  timestamp.strftime('%H:%M:%S.%3N')
rescue StandardError
  timestamp.to_s
end

def format_duration(seconds)
  if seconds < 60
    "#{seconds.round(1)}s"
  else
    mins = (seconds / 60).to_i
    secs = (seconds % 60).round(1)
    "#{mins}m #{secs}s"
  end
end

def display_tracking_summary(log_count, task_count, resource_count, status_updates)
  puts "📊 Tracking Summary:"
  puts "   Log entries: #{log_count}"
  puts "   Tasks: #{task_count}"
  puts "   Resources: #{resource_count}"
  puts "   Status updates: #{status_updates}"
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
    
    # Simple wait for cleanup - no need to track this one
    client.wait_for_operation(operation.id, timeout: 60)
    puts "✅ Test catlet cleaned up successfully"
  rescue StandardError => e
    puts "⚠️  Warning: Could not delete test catlet: #{e.message}"
  end
end

begin
  main
  puts "\nOperationTracker example completed"
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