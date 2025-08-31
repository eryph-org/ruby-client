#!/usr/bin/env ruby

# wait_for_operation Demo  
# Demonstrates the simple wait_for_operation method with callbacks in the Eryph Ruby client
# This creates a basic Ubuntu catlet and tracks the operation with a single callback block

require 'bundler/setup'
require 'eryph'
require 'time'

# Configuration
CONFIG_NAME = ENV['ERYPH_CONFIG'] || 'zero'  # Use 'zero' by default, override with env var
CATLET_NAME = "ruby-client-test-#{Time.now.strftime('%Y%m%d-%H%M%S')}"

puts "🚀 Eryph Ruby Client - wait_for_operation Demo"
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
  client_options[:verify_ssl] = false if CONFIG_NAME == 'zero'
  
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
  
  puts "📊 Tracking operation progress..."
  puts "   (Press Ctrl+C to interrupt)"
  puts
  
  result = client.wait_for_operation(operation.id, timeout: 600, poll_interval: 3) do |event_type, data|
    case event_type
    when :log_entry
      log_count += 1
      timestamp = format_timestamp(data.timestamp)
      puts "📝 [#{timestamp}] #{data.message}"
      
    when :task_new
      task_count += 1
      task_name = data.display_name || data.name
      puts "🔧 New Task: #{task_name} (ID: #{data.id})"
      
    when :task_update
      # Only show progress bars for tasks that are actively running (1-99%)
      if data.progress && data.progress > 0 && data.progress < 100
        progress_bar = ('█' * (data.progress / 5)).ljust(20, '░')
        puts "   📈 #{data.display_name || data.name}: [#{progress_bar}] #{data.progress}%"
      end
      
    when :resource_new
      resource_count += 1
      puts "🎯 Resource Created: #{data.resource_type} (ID: #{data.resource_id})"
      
    when :status
      status_updates += 1
      elapsed = format_duration(Time.now - start_time)
      puts "📊 Status: #{data.status} (elapsed: #{elapsed})"
    end
  end

  puts
  puts "=" * 50
  puts "✅ Operation completed!"
  puts "   Final Status: #{result.status}"
  puts "   Total Duration: #{format_duration(Time.now - start_time)}"
  puts "   Events Processed:"
  puts "     - Log entries: #{log_count}"
  puts "     - Tasks discovered: #{task_count}"  
  puts "     - Resources created: #{resource_count}"
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
  puts "✨ Demo completed successfully!"
  
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
  exit 1

rescue Interrupt
  puts
  puts "⛔ Interrupted by user"
  puts "   The operation may still be running in the background"
  puts "   Operation ID: #{operation.id}" if operation&.id
  exit 130

rescue => e
  puts "💥 Unexpected error: #{e.class}: #{e.message}"
  puts
  puts "Debug info:"
  puts "   Config: #{CONFIG_NAME}"
  puts "   Operation ID: #{operation.id}" if operation&.id
  puts
  puts "Backtrace:"
  e.backtrace.first(10).each { |line| puts "   #{line}" }
  exit 1
end