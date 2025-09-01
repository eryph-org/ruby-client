#!/usr/bin/env ruby

# OperationTracker Demo
# Demonstrates the advanced OperationTracker class with fluent callback API in the Eryph Ruby client
# This creates a basic Ubuntu catlet and tracks the operation with separate callbacks for each event type

require 'bundler/setup'
require 'eryph'
require 'time'

# Configuration
CONFIG_NAME = ENV['ERYPH_CONFIG'] || 'zero'  # Use 'zero' by default, override with env var
CATLET_NAME = "ruby-tracker-demo-#{Time.now.strftime('%Y%m%d-%H%M%S')}"

puts "🚀 Eryph Ruby Client - OperationTracker Demo"
puts "=" * 50
puts

def create_basic_catlet_config(name)
  # Using the generated ComputeClient models directly for the request
  ::ComputeClient::NewCatletRequest.new(
    configuration: {
      name: name,
      parent: 'dbosoft/ubuntu-22.04/starter',  # Basic Ubuntu 22.04 image
      cpu: { count: 1 },
      memory: { startup: 1024, minimum: 512, maximum: 2048 },
      # No additional disks or networks - use defaults
    }
  )
end

def format_timestamp(timestamp)
  timestamp.strftime('%H:%M:%S.%3N')
rescue
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

begin
  puts "📡 Connecting to Eryph (config: #{CONFIG_NAME})..."
  
  # Configure client options
  client_options = {
    scopes: %w[compute:write]  # Try with just compute:write since system client has that
  }
  
  # For eryph-zero, disable SSL verification since it uses self-signed certificates
  if CONFIG_NAME == 'zero'
    client_options[:ssl_config] = { verify_ssl: false }
  end
  
  puts "   Requesting scopes: #{client_options[:scopes].join(' ')}"
  
  client = Eryph.compute_client(CONFIG_NAME, **client_options)
  
  # Test connection
  puts "✅ Connected successfully!"
  puts "   Endpoint: #{client.compute_endpoint_url}"
  puts

  puts "🏗️  Creating catlet: #{CATLET_NAME}"
  catlet_config = create_basic_catlet_config(CATLET_NAME)
  
  # Initiate catlet creation
  operation = client.catlets.catlets_create(new_catlet_request: catlet_config)
  
  if !operation || !operation.id
    puts "❌ Failed to create catlet: No operation returned"
    exit 1
  end
  
  puts "   Operation ID: #{operation.id}"
  puts "   Status: #{operation.status}"
  puts

  # Track counters for display
  log_count = 0
  task_count = 0
  resource_count = 0
  status_updates = 0
  start_time = Time.now
  
  puts "📊 Tracking operation with OperationTracker..."
  puts "   (Press Ctrl+C to interrupt)"
  puts

  # Create OperationTracker and set up callbacks with fluent interface
  tracker = Eryph::Compute::OperationTracker.new(client, operation.id)
  
  tracker
    .on_log_entry do |log_entry|
      log_count += 1
      timestamp = format_timestamp(log_entry.timestamp)
      puts "📝 [#{timestamp}] #{log_entry.message}"
    end
    .on_task_new do |task|
      task_count += 1
      task_name = task.display_name || task.name
      puts "🔧 New Task: #{task_name} (ID: #{task.id})"
    end
    .on_task_update do |task|
      # Only show progress bars for tasks that are actively running (1-99%)
      if task.progress && task.progress > 0 && task.progress < 100
        progress_bar = ('█' * (task.progress / 5)).ljust(20, '░')
        puts "   📈 #{task.display_name || task.name}: [#{progress_bar}] #{task.progress}%"
      end
    end
    .on_resource_new do |resource|
      resource_count += 1
      puts "🎯 Resource Created: #{resource.resource_type} (ID: #{resource.resource_id})"
    end
    .on_status_change do |operation|
      status_updates += 1
      elapsed = format_duration(Time.now - start_time)
      puts "📊 Status: #{operation.status} (elapsed: #{elapsed})"
    end

  # Track the operation to completion
  result = tracker.track_to_completion(timeout: 600, poll_interval: 3)

  puts
  puts "=" * 50
  puts "✅ Operation completed!"
  puts "   Final Status: #{result.status}"
  puts "   Total Duration: #{format_duration(Time.now - start_time)}"
  
  # Show tracker statistics
  stats = tracker.stats
  puts "   Tracker Statistics:"
  puts "     - Log entries: #{stats[:processed_logs]}"
  puts "     - Tasks discovered: #{stats[:processed_tasks]}"  
  puts "     - Resources created: #{stats[:processed_resources]}"
  puts "     - Status updates: #{status_updates}"
  puts

  # Check results and fetch resources
  if result.completed?
    puts "🎉 Operation completed successfully!"
    
    # Show resource summary
    if result.resources.any?
      puts "   Resources created:"
      result.resources.each do |resource|
        puts "     - #{resource.resource_type}: #{resource.resource_id}"
      end
      
      # Try to fetch the actual catlet
      catlets = result.catlets
      if catlets.any?
        catlet = catlets.first
        puts
        puts "📋 Created Catlet Details:"
        puts "   ID: #{catlet.id}"
        puts "   Name: #{catlet.name}"
        puts "   Status: #{catlet.status}"
        puts "   VM ID: #{catlet.vm_id}" if catlet.respond_to?(:vm_id)
        puts "   CPU Count: #{catlet.cpu.count}" if catlet.respond_to?(:cpu) && catlet.cpu
        puts "   Memory: #{catlet.memory.startup}MB" if catlet.respond_to?(:memory) && catlet.memory
        
        # Show networks if available
        if catlet.networks && catlet.networks.any?
          puts "   Networks:"
          catlet.networks.each do |network|
            puts "     - #{network.name || 'default'}"
          end
        end
      end
    else
      puts "   No resources found in operation result"
    end
    
  elsif result.failed?
    puts "❌ Operation failed!"
    puts "   Error: #{result.status_message}" if result.status_message
    
    # Show recent log entries for debugging
    recent_logs = result.log_entries.last(5)
    if recent_logs.any?
      puts "   Recent logs:"
      recent_logs.each do |log|
        timestamp = format_timestamp(log.timestamp)
        puts "     [#{timestamp}] #{log.message}"
      end
    end
  end

  puts
  puts "✨ OperationTracker demo completed successfully!"
  puts
  puts "💡 Key OperationTracker Features Demonstrated:"
  puts "   - Fluent callback interface with method chaining"
  puts "   - Separate callbacks for each event type"
  puts "   - State tracking and statistics"
  puts "   - Flexible timeout and polling configuration"
  puts
  puts "📋 Catlet Management:"
  puts "   - The created catlet '#{CATLET_NAME}' is now available"
  puts

rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts "❌ Credentials Error: #{e.message}"
  puts
  puts "💡 Setup Help:"
  puts "   Make sure you have Eryph configured with one of these methods:"
  puts "   1. Run eryph-zero locally (for 'zero' config)"
  puts "   2. Configure a 'default' configuration with credentials"
  puts "   3. Set ERYPH_CONFIG environment variable to your config name"
  exit 1

rescue Timeout::Error => e
  puts "⏰ Operation timed out: #{e.message}"
  puts "   The operation may still be running in the background"
  puts "   Use tracker.stats to see what was processed: #{tracker.stats}" if defined?(tracker)
  exit 1

rescue Interrupt
  puts
  puts "⛔ Interrupted by user"
  puts "   The operation may still be running in the background"
  puts "   Operation ID: #{operation.id}" if operation&.id
  puts "   Tracker stats: #{tracker.stats}" if defined?(tracker)
  exit 130

rescue => e
  puts "💥 Unexpected error: #{e.class}: #{e.message}"
  puts
  puts "Debug info:"
  puts "   Config: #{CONFIG_NAME}"
  puts "   Operation ID: #{operation.id}" if operation&.id
  puts "   Tracker stats: #{tracker.stats}" if defined?(tracker)
  puts
  puts "Backtrace:"
  e.backtrace.first(10).each { |line| puts "   #{line}" }
  exit 1
end