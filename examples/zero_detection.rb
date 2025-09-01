#!/usr/bin/env ruby

# Eryph-Zero Detection Example
# This example demonstrates automatic discovery of running eryph-zero instances

require_relative '../lib/eryph'


puts "🔍 Eryph-Zero Detection Example"
puts "=" * 40

begin
  # Check if eryph-zero is running
  puts "\n📡 Checking for running eryph-zero instance..."
  
  if Eryph.zero_running?
    puts "✅ Eryph-zero is running!"
    
    # Get discovered endpoints
    puts "\n🌐 Discovered endpoints:"
    endpoints = Eryph.zero_endpoints
    endpoints.each do |name, url|
      puts "  #{name.capitalize}: #{url}"
    end
    
    # Test credentials availability
    puts "\n🔑 Testing credential availability..."
    if Eryph.credentials_available?('zero')
      puts "✅ Zero credentials are available (using system-client)"
      
      # Create client using discovered configuration
      puts "\n📡 Creating compute client..."
      client = Eryph.compute_client('zero', ssl_config: { verify_ssl: false })
      
      puts "Client configuration: #{client.config_name}"
      puts "Endpoint: #{client.endpoint_name}"
      
      # Test connection
      puts "\n🔗 Testing connection..."
      if client.test_connection
        puts "✅ Successfully connected to eryph-zero!"
        puts "Access Token: #{client.access_token[0..20]}..." if client.access_token
        
        # Try some basic operations (placeholder responses until generated client is available)
        puts "\n📋 Testing API operations..."
        
        puts "📁 Projects:"
        projects_response = client.projects.projects_list
        puts "  Response: #{projects_response}"
        
        puts "🐱 Catlets:"
        catlets_response = client.catlets.catlets_list
        puts "  Response: #{catlets_response}"
        
      else
        puts "❌ Connection test failed"
      end
      
    else
      puts "❌ Zero credentials not available"
      puts "  This might happen if:"
      puts "  - eryph-zero system-client key is not accessible"
      puts "  - File permissions prevent reading the private key"
      puts "  - eryph-zero is running with different security settings"
    end
    
  else
    puts "❌ Eryph-zero is not running"
    puts "\n💡 To use eryph-zero:"
    puts "  1. Start eryph-zero: 'eryph-zero run'"
    puts "  2. Wait for it to initialize"
    puts "  3. Run this script again"
    puts "\n📝 Or manually configure credentials:"
    puts "  1. Create .eryph/zero.config with endpoint configuration"
    puts "  2. Store client credentials in .eryph/private/{client-id}.key"
  end

rescue Eryph::ClientRuntime::ConfigurationError => e
  puts "❌ Configuration error: #{e.message}"
rescue Eryph::ClientRuntime::TokenRequestError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "  Check eryph-zero logs for authentication issues"
rescue => e
  puts "❌ Unexpected error: #{e.message}"
  puts e.backtrace if ENV['DEBUG']
end

puts "\n✅ Zero detection example completed!"