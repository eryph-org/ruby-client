#!/usr/bin/env ruby

# Basic usage example for the Eryph Ruby Compute Client
# This example demonstrates the most common operations

require_relative '../lib/eryph'

# Create a client with automatic credential discovery
# The client will automatically discover credentials from multiple configuration sources
# in priority order: default → zero → local (Windows), or default → local (Unix)

# Option 1: Automatic discovery (recommended - tries multiple configs)
client = Eryph.compute_client(ssl_config: { verify_ssl: false }) # Auto-discovers best available credentials

# Option 2: Specific configuration  
# client = Eryph.compute_client('zero', ssl_config: { verify_ssl: false }) # uses 'zero' configuration only
# client = Eryph.compute_client('production') # uses 'production' configuration

# Option 3: Specific client ID (searches across all configs)
# client = Eryph.compute_client(client_id: 'my-specific-client', ssl_config: { verify_ssl: false })

begin
  # Test the connection
  puts "🔍 Testing connection..."
  puts "   Token endpoint: #{client.instance_variable_get(:@token_provider).credentials.token_endpoint}"
  if client.test_connection
    puts "✅ Connected successfully!"
    puts "   Configuration: #{client.config_name}"
    puts "   Access Token: #{client.access_token[0..20]}..." if client.access_token
  else
    puts "❌ Connection failed"
    exit 1
  end

  # Note: The following API calls return placeholder responses until the 
  # generated client is created. Run ./generate.ps1 to generate the actual API client.

  # List all projects
  puts "\n📁 Listing projects..."
  projects_response = client.projects.projects_list
  puts "Response: #{projects_response}"

  # List all catlets
  puts "\n🐱 Listing catlets..."
  catlets_response = client.catlets.catlets_list
  puts "Response: #{catlets_response}"

  # List operations
  puts "\n⚙️  Listing recent operations..."
  operations_response = client.operations.operations_list
  puts "Response: #{operations_response}"

  # List virtual disks
  puts "\n💾 Listing virtual disks..."
  disks_response = client.virtual_disks.virtual_disks_list
  puts "Response: #{disks_response}"

  # List genes
  puts "\n🧬 Listing genes..."
  genes_response = client.genes.genes_list
  puts "Response: #{genes_response}"

rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts "❌ Credentials not found: #{e.message}"
  puts "   Please set up configuration files or check your .eryph directory"
  puts "   Run 'Eryph.credentials_available?' to test credential availability"
  exit 1
rescue Eryph::ClientRuntime::TokenRequestError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "   Check your client credentials and network connectivity"
  exit 1
rescue Eryph::Compute::ApiError => e
  puts "❌ API Error: #{e.message}"
  puts "   Response Code: #{e.code}" if e.respond_to?(:code)
  puts "   Response Body: #{e.response_body}" if e.respond_to?(:response_body)
  exit 1
rescue => e
  puts "❌ Unexpected error: #{e.message}"
  puts e.backtrace if ENV['DEBUG']
  exit 1
end

puts "\n✅ Example completed successfully!"