#!/usr/bin/env ruby

# Catlet management example for the Eryph Ruby Compute Client
# This example shows how to create, manage, and control catlets

require_relative '../lib/eryph'

# Create client using configuration-based authentication
client = Eryph.compute_client('zero', ssl_config: { verify_ssl: false })

# This example now uses the built-in client.wait_for_operation method

begin
  puts "🐱 Eryph Catlet Management Example"
  puts "=" * 40

  # Test basic client connectivity first
  puts "\n🔍 Testing client connection..."
  puts "   Configuration: #{client.config_name}"
  puts "   Compute endpoint: #{client.compute_endpoint_url}"
  
  # Try to get version info as a basic connectivity test
  begin
    version_info = client.version.version_get
    puts "✅ Successfully connected to compute API"
    puts "   API Version: #{version_info.version}" if version_info.respond_to?(:version)
  rescue => version_error
    puts "⚠️  Warning: Could not get version info - #{version_error.message}"
    puts "   This suggests the compute API may not be running or accessible"
    puts "   Continuing with catlet creation attempt..."
  end

  # Create a new catlet
  puts "\n📝 Creating a new catlet..."
  
  catlet_config = {
    name: "example-catlet-#{Time.now.to_i}",
    parent: "dbosoft/winsrv2019-standard/starter",
    cpu: { count: 2 },
    memory: { startup: 2048, minimum: 1024, maximum: 4096 }
  }

  create_request = Eryph::ComputeClient::NewCatletRequest.new(configuration: catlet_config)
  create_operation = client.catlets.catlets_create(new_catlet_request: create_request)
  
  puts "🚀 Catlet creation initiated (Operation: #{create_operation.id})"
  
  # Wait for creation to complete
  completed_operation = client.wait_for_operation(create_operation.id)
  
  if completed_operation.status == 'Completed'
    # Find the catlet by name since operation resources may not return the correct ID
    catlet_name = catlet_config[:name]
    puts "🔍 Looking for catlet by name: #{catlet_name}"
    
    catlets = client.catlets.catlets_list
    created_catlet = catlets.value.find { |c| c.name == catlet_name }
    
    if created_catlet
      catlet_id = created_catlet.id
      puts "✅ Catlet created successfully with ID: #{catlet_id}"
    else
      puts "⚠️  Catlet creation completed but catlet not found in list"
      puts "Operation ID: #{completed_operation.id}"
      puts "Expected name: #{catlet_name}"
      exit 1
    end
    
    # Get catlet details
    puts "\n📊 Fetching catlet details..."
    catlet = client.catlets.catlets_get(catlet_id)
    puts "Name: #{catlet.name}"
    puts "Status: #{catlet.status}"
    puts "VM ID: #{catlet.vm_id}"
    puts "Project: #{catlet.project.name}"
    
    # Start the catlet
    puts "\n▶️  Starting catlet..."
    start_operation = client.catlets.catlets_start(catlet_id)
    start_result = client.wait_for_operation(start_operation.id)
    
    if start_result.status == 'Completed'
      puts "✅ Catlet started successfully!"
      
      # Check status
      catlet = client.catlets.catlets_get(catlet_id)
      puts "Current status: #{catlet.status}"
      
      # Wait a bit, then stop the catlet
      puts "\n⏸️  Waiting 30 seconds before stopping..."
      sleep 30
      
      puts "⏹️  Stopping catlet..."
      stop_request = Eryph::ComputeClient::StopCatletRequestBody.new(
        mode: Eryph::ComputeClient::CatletStopMode::SHUTDOWN
      )
      stop_operation = client.catlets.catlets_stop(catlet_id, stop_request)
      stop_result = client.wait_for_operation(stop_operation.id)
      
      if stop_result.status == 'Completed'
        puts "✅ Catlet stopped successfully!"
        
        # Final status check
        catlet = client.catlets.catlets_get(catlet_id)
        puts "Final status: #{catlet.status}"
        
        # Optionally delete the catlet
        puts "\n🗑️  Do you want to delete the catlet? (y/N)"
        response = gets.chomp.downcase
        
        if response == 'y' || response == 'yes'
          puts "🗑️  Deleting catlet..."
          delete_operation = client.catlets.catlets_delete(catlet_id)
          delete_result = client.wait_for_operation(delete_operation.id)
          
          if delete_result.status == 'Completed'
            puts "✅ Catlet deleted successfully!"
          else
            puts "❌ Failed to delete catlet: #{delete_result.status_message}"
          end
        else
          puts "ℹ️  Catlet preserved. You can manage it manually."
        end
        
      else
        puts "❌ Failed to stop catlet: #{stop_result.status_message}"
      end
      
    else
      puts "❌ Failed to start catlet: #{start_result.status_message}"
    end
    
  else
    puts "❌ Failed to create catlet: #{completed_operation.status_message}"
  end

rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts "❌ Credentials not found: #{e.message}"
  puts "   Please set up configuration files in .eryph directory"
  puts "   See README.md for configuration file format and locations"
  exit 1
rescue Eryph::ClientRuntime::TokenRequestError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "   Check your client credentials and network connectivity"
  exit 1
rescue Eryph::ComputeClient::ApiError => e
  puts "❌ Generated API Error: #{e.message}"
  puts "   Response Code: #{e.code}" if e.respond_to?(:code)
  puts "   Response Body: #{e.response_body}" if e.respond_to?(:response_body)
  puts "   Full error details:"
  puts "     Class: #{e.class}"
  puts "     Message: #{e.message}"
  puts "   Backtrace:" if ENV['DEBUG']
  puts e.backtrace.join("\n     ") if ENV['DEBUG']
  exit 1
rescue Faraday::ConnectionFailed => e
  puts "❌ Connection failed: #{e.message}"
  puts "   Check that the compute endpoint is running and accessible"
  puts "   Full error details:"
  puts "     Class: #{e.class}"
  puts "     Message: #{e.message}"
  puts "   Backtrace:" if ENV['DEBUG']
  puts e.backtrace.join("\n     ") if ENV['DEBUG']
  exit 1
rescue Faraday::TimeoutError => e
  puts "❌ Connection timeout: #{e.message}"
  puts "   The compute endpoint is not responding within the timeout period"
  puts "   Full error details:"
  puts "     Class: #{e.class}"
  puts "     Message: #{e.message}"
  exit 1
rescue Interrupt
  puts "\n\n⏹️  Interrupted by user"
  exit 1
rescue => e
  puts "❌ Unexpected error: #{e.message}"
  puts "   Full error details:"
  puts "     Class: #{e.class}"
  puts "     Message: #{e.message}"
  puts "   Backtrace:"
  puts e.backtrace.join("\n     ")
  exit 1
end

puts "\n✅ Catlet management example completed!"