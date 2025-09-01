#!/usr/bin/env ruby

# Test Catlet Config Demo
# Demonstrates catlet configuration testing and operation result extraction in the Eryph Ruby client
# This validates and expands catlet configurations, showing the new typed result handling

require 'bundler/setup'
require 'eryph'
require 'json'
require 'yaml'
require 'time'

# Configuration
CONFIG_NAME = ENV['ERYPH_CONFIG'] || 'zero'  # Use 'zero' by default, override with env var

puts "🧪 Eryph Ruby Client - Test Catlet Config Demo"
puts "=" * 55
puts

def create_test_catlet_config(name = nil)
  config = {
    name: name || "test-catlet-#{Time.now.strftime('%Y%m%d-%H%M%S')}",
    parent: 'dbosoft/ubuntu-22.04/starter',
    cpu: { count: 2 },
    memory: { startup: 2048, minimum: 1024, maximum: 4096 },
    networks: [
      { name: 'default' }
    ],
    drives: [
      {
        name: 'data',
        size: 20,
        location: '/data'
      }
    ],
    variables: {
      hostname: '{{catlet_name}}-host',
      environment: 'development'
    }
  }
  
  # Convert to JSON element for the API
  JSON.generate(config)
end

def create_valid_catlet_config(name = nil)
  config = {
    name: name || "valid-catlet-#{Time.now.strftime('%Y%m%d-%H%M%S')}",
    parent: 'dbosoft/ubuntu-22.04/starter',
    cpu: { count: 1 },
    memory: { startup: 1024, minimum: 512, maximum: 2048 }
  }
  
  # Convert to JSON element for the API
  JSON.generate(config)
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

def display_config_yaml(config_json)
  begin
    # Pretty print the configuration as YAML for readability
    config_hash = JSON.parse(config_json)
    puts YAML.dump(config_hash).lines[1..-1].join  # Skip the first line (---)
  rescue => e
    puts "Error formatting config: #{e.message}"
    puts config_json
  end
end

def demo_quick_validation(client, config_json)
  puts "🔍 Quick Configuration Validation"
  puts "-" * 35
  
  begin
    # Use the convenient validate_catlet_config method (accepts JSON string or Ruby hash)
    result = client.validate_catlet_config(config_json)
    
    puts "✅ Validation completed!"
    puts "   Valid: #{result.is_valid ? 'Yes' : 'No'}"
    
    if result.errors && result.errors.any?
      puts "   Errors found:"
      result.errors.each do |error|
        if error.respond_to?(:message)
          location = error.respond_to?(:path) && error.path ? " (#{error.path})" : ""
          puts "     - #{error.message}#{location}"
        else
          puts "     - #{error}"
        end
      end
    else
      puts "   No validation errors found"
    end
    
    puts
    return result.is_valid
    
  rescue Eryph::Compute::ProblemDetailsError => e
    puts "❌ Validation failed with problem details:"
    puts "   Title: #{e.title}"
    puts "   Detail: #{e.detail}"
    puts "   Type: #{e.problem_type}"
    puts
    return false
    
  rescue => e
    puts "❌ Validation error: #{e.class}: #{e.message}"
    puts
    return false
  end
end

def demo_hash_validation(client)
  puts "🔍 Ruby Hash Configuration Validation"
  puts "-" * 38
  
  begin
    # Demonstrate validation with Ruby hash (like vagrant plugin usage)
    config_hash = {
      name: "hash-demo-catlet",
      parent: 'dbosoft/ubuntu-22.04/starter',
      cpu: { count: 1 },
      memory: { startup: 1024, minimum: 512, maximum: 2048 }
    }
    
    puts "   Using Ruby Hash input (like Vagrant):"
    puts "   #{config_hash.inspect}"
    puts
    
    # Use the convenient validate_catlet_config method with Ruby hash
    result = client.validate_catlet_config(config_hash)
    
    puts "✅ Hash validation completed!"
    puts "   Valid: #{result.is_valid ? 'Yes' : 'No'}"
    
    if result.errors && result.errors.any?
      puts "   Errors found:"
      result.errors.each do |error|
        puts "     - #{error}"
      end
    else
      puts "   No validation errors found"
    end
    
    puts
    return result.is_valid
    
  rescue Eryph::Compute::ProblemDetailsError => e
    puts "❌ Hash validation failed with problem details:"
    puts "   Title: #{e.title}"
    puts "   Detail: #{e.detail}"
    puts
    return false
    
  rescue => e
    puts "❌ Hash validation error: #{e.class}: #{e.message}"
    puts
    return false
  end
end

def demo_config_expansion(client, config_json, test_name)
  puts "🔧 #{test_name}"
  puts "-" * (test_name.length + 4)
  
  begin
    # Create the expand request
    request = ComputeClient::ExpandNewCatletConfigRequest.new(
      configuration: JSON.parse(config_json),
      correlation_id: SecureRandom.uuid,
      show_secrets: false
    )
    
    # Start the expansion operation
    operation = client.catlets.catlets_expand_new_config(expand_new_catlet_config_request: request)
    
    if !operation || !operation.id
      puts "❌ Failed to start configuration expansion"
      return false
    end
    
    puts "   Operation ID: #{operation.id}"
    puts "   Initial Status: #{operation.status}"
    
    # Simple wait without detailed progress tracking
    start_time = Time.now
    result = client.wait_for_operation(operation.id, timeout: 120, poll_interval: 2) do |event_type, data|
      case event_type
      when :status
        elapsed = format_duration(Time.now - start_time)
        puts "   Status: #{data.status} (#{elapsed})"
      when :log_entry
        puts "   📝 #{data.message}" if data.message
      end
    end
    
    puts
    
    if result.completed?
      puts "✅ Configuration expansion completed!"
      
      # Show operation result information
      if result.has_result?
        puts "   Result Type: #{result.result_type}"
        
        if typed_result = result.typed_result
          case typed_result
          when Eryph::Compute::CatletConfigResult
            puts "   📋 Catlet Configuration:"
            
            if typed_result.has_configuration?
              puts "     ✅ SUCCESS! Configuration extracted from raw JSON:"
              puts "     Name: #{typed_result.name}"
              puts "     Parent: #{typed_result.parent}"
              puts
              display_config_yaml(JSON.generate(typed_result.configuration))
            else
              puts "     ❌ Failed to extract configuration"
            end
          else
            puts "   ✅ Operation completed with typed result: #{typed_result.class}"
          end
        else
          puts "   ✅ Operation completed with result"
        end
      else
        puts "   ⚠️  No result data in completed operation"
      end
      
      puts
      return true
      
    elsif result.failed?
      puts "❌ Configuration expansion failed!"
      puts "   Error: #{result.status_message}" if result.status_message
      
      # Show recent log entries for debugging
      if result.log_entries.any?
        puts "   Recent logs:"
        result.log_entries.last(3).each do |log|
          puts "     #{log.message}" if log.message
        end
      end
      
      puts
      return false
    else
      puts "⚠️  Operation ended with unexpected status: #{result.status}"
      puts
      return false
    end
    
  rescue Eryph::Compute::ProblemDetailsError => e
    puts "❌ API Error with Problem Details:"
    puts "   Title: #{e.title}"
    puts "   Detail: #{e.detail}"
    puts "   Problem Type: #{e.problem_type}"
    puts "   HTTP Status: #{e.code}"
    puts
    return false
    
  rescue => e
    puts "❌ Unexpected error: #{e.class}: #{e.message}"
    puts
    return false
  end
end

begin
  puts "📡 Connecting to Eryph (config: #{CONFIG_NAME})..."
  
  # Configure client options
  client_options = {
    scopes: %w[compute:write]
  }
  logger = Logger.new($stdout)
  logger.level = Logger::DEBUG

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
  
  # Create test configurations - one invalid to show validation errors, one valid for expansion
  invalid_config = create_test_catlet_config("demo-test-catlet")
  valid_config = create_valid_catlet_config("demo-valid-catlet")
  
  puts "📄 Test Configuration (with validation errors):"
  puts "-" * 48
  display_config_yaml(invalid_config)
  puts
  
  # Demo 1: Quick validation (no operation tracking) - using invalid config to show error handling
  puts "Using invalid config to demonstrate validation error handling..."
  puts
  valid = demo_quick_validation(client, invalid_config)
  
  # Demo 2: Ruby hash validation (like vagrant plugin usage)
  hash_valid = demo_hash_validation(client)
  
  # Demo 3: Configuration expansion (with operation result extraction) - using valid config
  puts "📄 Valid Configuration for Expansion Demo:"
  puts "-" * 42
  display_config_yaml(valid_config)
  puts
  
  puts "Using valid config for expansion demo..."
  puts
  success = demo_config_expansion(client, valid_config, "Configuration Expansion with Variable Resolution")
  
  if success
    puts "🎉 All demos completed successfully!"
    puts
    puts "Key Features Demonstrated:"
    puts "   ✅ Quick configuration validation with JSON strings"
    puts "   ✅ Ruby hash validation (Vagrant-style API)"
    puts "   ✅ Operation tracking with simple callbacks"
    puts "   ✅ Typed operation result extraction"
    puts "   ✅ CatletConfig result handling"
    puts "   ✅ Enhanced error handling with ProblemDetails"
  else
    puts "⚠️  Configuration expansion demo failed"
    puts "   But validation (JSON and hash) was demonstrated successfully"
  end
  
  puts
  puts "✨ Demo completed!"
  
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
  exit 130

rescue Eryph::Compute::ProblemDetailsError => e
  puts "💥 API Error: #{e.friendly_message}"
  puts "   Problem Type: #{e.problem_type}" if e.problem_type
  puts "   HTTP Status: #{e.code}" if e.code
  puts "   Instance: #{e.instance}" if e.instance
  exit 1

rescue => e
  puts "💥 Unexpected error: #{e.class}: #{e.message}"
  puts
  puts "Debug info:"
  puts "   Config: #{CONFIG_NAME}"
  puts
  puts "Backtrace:"
  e.backtrace.first(5).each { |line| puts "   #{line}" }
  exit 1
end