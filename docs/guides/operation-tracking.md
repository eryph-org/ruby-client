# Operation Tracking Guide

This guide covers advanced operation monitoring and tracking capabilities in the Eryph Ruby Client, including real-time progress monitoring, event handling, and operation result processing.

## Overview

Eryph operations are asynchronous tasks that can take time to complete. The Ruby client provides comprehensive tracking capabilities to monitor progress, handle events, and process results.

## Operation Lifecycle

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Queued    │───▶│   Running   │───▶│  Completed  │    │   Failed    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │              │
       ▼                   ▼                   ▼              ▼
  ┌────────────────────────────────────────────────────────────────┐
  │              Event Stream (Logs, Tasks, Resources)            │
  └────────────────────────────────────────────────────────────────┘
```

## Basic Operation Tracking

### Start an Operation

```ruby
require 'eryph'

client = Eryph.compute_client

# Create a catlet (returns operation immediately)
new_catlet_request = {
  name: 'my-catlet',
  project: 'default',
  config: {
    parent: 'dbosoft/ubuntu-22.04/starter',
    cpu: { count: 2 },
    memory: { startup: 2048 }
  }
}

operation = client.catlets.catlets_create(new_catlet_request: new_catlet_request)
puts "Operation started: #{operation.id}"
puts "Status: #{operation.status}"
```

### Simple Wait for Completion

```ruby
# Wait for completion (default timeout: 300 seconds)
result = client.wait_for_operation(operation.id)

if result.succeeded?
  puts "✅ Operation completed successfully!"
  puts "Status: #{result.status}"
  puts "Result type: #{result.result_type}"
else
  puts "❌ Operation failed: #{result.status_message}"
end
```

### Custom Timeout and Polling

```ruby
# Wait with custom settings
result = client.wait_for_operation(
  operation.id,
  timeout: 600,      # 10 minutes
  poll_interval: 2   # Check every 2 seconds
)
```

## Advanced Event Handling

### Real-time Progress Monitoring

```ruby
# Monitor operation with detailed progress
result = client.wait_for_operation(operation.id) do |event_type, data|
  case event_type
  when :log_entry
    # New log entry
    timestamp = data.timestamp.strftime('%H:%M:%S')
    puts "[#{timestamp}] #{data.message}"
    
  when :task_new
    # New task started
    puts "🔵 Task started: #{data.name || data.type} (#{data.id})"
    
  when :task_update
    # Task progress update
    progress = data.progress ? "#{data.progress}%" : "running"
    puts "   Task #{data.id}: #{data.status} (#{progress})"
    
  when :resource_new
    # New resource created
    puts "📦 Resource created: #{data.type} #{data.id}"
    
  when :status
    # Overall operation status update
    puts "Status: #{data.status}"
  end
end
```

### Filtering Events by Type

```ruby
# Only show log messages
result = client.wait_for_operation(operation.id) do |event_type, data|
  next unless event_type == :log_entry
  
  level = data.level || 'INFO'
  puts "[#{level}] #{data.message}"
end

# Only show task updates
result = client.wait_for_operation(operation.id) do |event_type, data|
  case event_type
  when :task_new
    puts "▶️  #{data.name}: Started"
  when :task_update
    puts "🔄 #{data.name}: #{data.status}"
  end
end
```

### Progress Bar Implementation

```ruby
# Simple progress tracking
tasks = {}
total_tasks = 0

result = client.wait_for_operation(operation.id) do |event_type, data|
  case event_type
  when :task_new
    tasks[data.id] = { name: data.name, status: 'Running' }
    total_tasks += 1
    puts "Tasks: #{total_tasks} total"
    
  when :task_update
    if tasks[data.id]
      tasks[data.id][:status] = data.status
      completed = tasks.values.count { |t| t[:status] == 'Completed' }
      failed = tasks.values.count { |t| t[:status] == 'Failed' }
      running = tasks.values.count { |t| t[:status] == 'Running' }
      
      puts "Progress: #{completed}/#{total_tasks} completed, #{failed} failed, #{running} running"
    end
  end
end
```

## Operation Results and Typed Data

### Accessing Typed Results

```ruby
result = client.wait_for_operation(operation.id)

if result.succeeded?
  # Get typed result based on operation type
  case result.result_type
  when 'Catlet'
    catlet = result.typed_result
    puts "Created catlet: #{catlet.name}"
    puts "Catlet ID: #{catlet.id}"
    puts "Status: #{catlet.status}"
    
  when 'CatletConfig'
    config = result.typed_result
    puts "Config name: #{config.name}"
    puts "Parent: #{config.parent}"
    
  when 'VirtualDisk'
    disk = result.typed_result
    puts "Created disk: #{disk.name}"
    puts "Size: #{disk.size_bytes} bytes"
    
  else
    puts "Unknown result type: #{result.result_type}"
  end
else
  puts "Operation failed: #{result.status_message}"
end
```

### Handling Different Operation Types

```ruby
def handle_operation_result(result)
  return puts "❌ Operation failed: #{result.status_message}" unless result.succeeded?
  
  case result.result_type
  when 'Catlet'
    handle_catlet_result(result.typed_result)
  when 'CatletConfig'
    handle_config_result(result.typed_result)
  when 'Operation'
    handle_nested_operation(result.typed_result)
  else
    puts "✅ Operation completed (#{result.result_type})"
  end
end

def handle_catlet_result(catlet)
  puts "✅ Catlet ready: #{catlet.name}"
  puts "   ID: #{catlet.id}"
  puts "   Status: #{catlet.status}"
  puts "   CPU: #{catlet.cpu_count} cores" if catlet.cpu_count
  puts "   Memory: #{catlet.memory_startup}MB" if catlet.memory_startup
end

def handle_config_result(config)
  puts "✅ Configuration validated: #{config.name}"
  puts "   Parent: #{config.parent}"
  puts "   Has valid structure: #{config.has_configuration?}"
end
```

## Error Handling and Timeouts

### Handling Timeouts

```ruby
begin
  result = client.wait_for_operation(operation.id, timeout: 60)
  puts "Operation completed within 1 minute"
rescue Timeout::Error
  puts "⏰ Operation timed out after 60 seconds"
  
  # Check current status
  current_op = client.operations.operations_get(operation.id)
  puts "Current status: #{current_op.status}"
  
  if current_op.status == 'Running'
    puts "Operation is still running, you can continue waiting..."
    # Optionally continue waiting
    result = client.wait_for_operation(operation.id, timeout: 300)
  end
end
```

### Handling Operation Failures

```ruby
result = client.wait_for_operation(operation.id) do |event_type, data|
  if event_type == :log_entry && data.level == 'ERROR'
    puts "🔴 ERROR: #{data.message}"
  end
end

unless result.succeeded?
  puts "❌ Operation failed"
  puts "Status: #{result.status}"
  puts "Message: #{result.status_message}"
  
  # Get detailed error information
  operation_details = client.operations.operations_get(operation.id, expand: "logs")
  
  error_logs = operation_details.log_entries&.select { |log| log.level == 'ERROR' }
  if error_logs && error_logs.any?
    puts "\nError details:"
    error_logs.each { |log| puts "  - #{log.message}" }
  end
end
```

## Operation Management

### Manual Operation Polling

```ruby
# Poll manually without waiting
operation_id = "your-operation-id"
last_check = Time.now - 300  # Check last 5 minutes of logs

loop do
  operation = client.operations.operations_get(
    operation_id,
    expand: "logs,tasks,resources",
    log_time_stamp: last_check
  )
  
  puts "Status: #{operation.status}"
  
  # Process new events
  operation.log_entries&.each do |log|
    puts "[LOG] #{log.message}" if log.timestamp > last_check
  end
  
  last_check = Time.now
  
  break if ['Completed', 'Failed'].include?(operation.status)
  sleep 5
end
```

### Operation History and Querying

```ruby
# List recent operations
operations = client.operations.operations_list(
  expand: "logs",
  top: 10  # Last 10 operations
)

operations.each do |op|
  status_icon = case op.status
                when 'Completed' then '✅'
                when 'Failed' then '❌'
                when 'Running' then '🔄'
                else '⏳'
                end
  
  puts "#{status_icon} #{op.id}: #{op.status} (#{op.created_at})"
end

# Find operations by type or resource
catlet_operations = operations.select do |op|
  op.resources&.any? { |r| r.type == 'Catlet' }
end

puts "Found #{catlet_operations.length} catlet operations"
```

## Advanced Patterns

### Operation Chaining

```ruby
# Chain multiple operations
def create_and_configure_catlet(client, catlet_config)
  # Step 1: Create catlet
  puts "🔵 Creating catlet..."
  create_op = client.catlets.catlets_create(new_catlet_request: catlet_config)
  create_result = client.wait_for_operation(create_op.id)
  
  return create_result unless create_result.succeeded?
  
  catlet = create_result.typed_result
  puts "✅ Catlet created: #{catlet.id}"
  
  # Step 2: Start catlet  
  puts "🔵 Starting catlet..."
  start_op = client.catlets.catlets_start(catlet.id)
  start_result = client.wait_for_operation(start_op.id)
  
  return start_result unless start_result.succeeded?
  
  puts "✅ Catlet started successfully!"
  start_result
end

# Use the chaining function
config = {
  name: 'web-server',
  project: 'default',
  config: { parent: 'dbosoft/ubuntu-22.04/starter' }
}

result = create_and_configure_catlet(client, config)
puts result.succeeded? ? "🎉 All done!" : "❌ Failed: #{result.status_message}"
```

### Parallel Operation Tracking

```ruby
# Track multiple operations simultaneously
def track_multiple_operations(client, operation_ids)
  results = {}
  threads = []
  
  operation_ids.each do |op_id|
    threads << Thread.new do
      begin
        result = client.wait_for_operation(op_id) do |event_type, data|
          puts "[#{op_id}] #{event_type}: #{data.respond_to?(:message) ? data.message : data.status}"
        end
        results[op_id] = result
      rescue => e
        puts "[#{op_id}] Error: #{e.message}"
        results[op_id] = nil
      end
    end
  end
  
  # Wait for all to complete
  threads.each(&:join)
  
  # Report results
  results.each do |op_id, result|
    status = result ? (result.succeeded? ? '✅' : '❌') : '💥'
    puts "#{status} #{op_id}: #{result&.status || 'Error'}"
  end
  
  results
end

# Example usage
operation_ids = ['op-1', 'op-2', 'op-3']
results = track_multiple_operations(client, operation_ids)
```

### Custom Event Processors

```ruby
class OperationTracker
  def initialize(client)
    @client = client
    @handlers = {}
  end
  
  def on(event_type, &block)
    @handlers[event_type] = block
    self
  end
  
  def track(operation_id, timeout: 300)
    @client.wait_for_operation(operation_id, timeout: timeout) do |event_type, data|
      handler = @handlers[event_type]
      handler.call(data) if handler
    end
  end
end

# Usage
tracker = OperationTracker.new(client)
  .on(:log_entry) { |log| puts "📝 #{log.message}" }
  .on(:task_new) { |task| puts "🆕 Task: #{task.name}" }
  .on(:task_update) { |task| puts "🔄 #{task.name}: #{task.status}" }
  .on(:resource_new) { |resource| puts "📦 Created: #{resource.type}" }

result = tracker.track(operation.id)
```

## Performance Considerations

### Optimizing Polling

```ruby
# Adaptive polling - slower when running long
def adaptive_wait_for_operation(client, operation_id)
  start_time = Time.now
  poll_interval = 1
  
  client.wait_for_operation(operation_id, poll_interval: poll_interval) do |event_type, data|
    # Increase polling interval for long-running operations
    elapsed = Time.now - start_time
    if elapsed > 60 && poll_interval < 10
      poll_interval = [poll_interval * 1.5, 10].min
      puts "📊 Adjusting poll interval to #{poll_interval}s"
    end
    
    # Handle events...
    puts "[#{event_type}] #{data.respond_to?(:message) ? data.message : data.inspect}"
  end
end
```

### Limiting Event Processing

```ruby
# Process only recent events to avoid overwhelming output
MAX_LOG_ENTRIES = 50
log_count = 0

result = client.wait_for_operation(operation.id) do |event_type, data|
  case event_type
  when :log_entry
    log_count += 1
    if log_count <= MAX_LOG_ENTRIES
      puts "[LOG] #{data.message}"
    elsif log_count == MAX_LOG_ENTRIES + 1
      puts "... (suppressing further log entries for performance)"
    end
  when :status
    puts "Status: #{data.status}"
  end
end
```

## Troubleshooting

### Debug Operation Issues

```ruby
# Comprehensive operation debugging
def debug_operation(client, operation_id)
  puts "🔍 Debugging operation #{operation_id}"
  
  # Get full operation details
  operation = client.operations.operations_get(
    operation_id,
    expand: "logs,tasks,resources"
  )
  
  puts "Status: #{operation.status}"
  puts "Created: #{operation.created_at}"
  puts "Updated: #{operation.updated_at}"
  puts "Message: #{operation.status_message}" if operation.status_message
  
  # Show tasks
  if operation.tasks&.any?
    puts "\nTasks:"
    operation.tasks.each do |task|
      puts "  - #{task.id}: #{task.status} (#{task.name || task.type})"
      puts "    Progress: #{task.progress}%" if task.progress
    end
  end
  
  # Show resources
  if operation.resources&.any?
    puts "\nResources:"
    operation.resources.each do |resource|
      puts "  - #{resource.id}: #{resource.type}"
    end
  end
  
  # Show recent error logs
  if operation.log_entries&.any?
    error_logs = operation.log_entries.select { |log| log.level == 'ERROR' }
    if error_logs.any?
      puts "\nError Logs:"
      error_logs.last(10).each do |log|
        puts "  [#{log.timestamp}] #{log.message}"
      end
    end
  end
end

# Usage
debug_operation(client, 'problematic-operation-id')
```

## Next Steps

- [Getting Started Guide](getting-started.md) - Basic client usage
- [Authentication Guide](authentication.md) - Credential setup
- [Configuration Guide](configuration.md) - Environment management
- [API Reference](../ruby-api/) - Complete method documentation
- [Examples](../examples/) - Working code examples