#!/usr/bin/env ruby

# Basic usage example for the Eryph Ruby Compute Client
# Demonstrates client creation, authentication, and basic API operations

require_relative '../lib/eryph'

def main
  puts 'Eryph Ruby Client - Basic Usage Example'
  puts '=' * 40
  puts "This example demonstrates:"
  puts "• Automatic credential discovery"
  puts "• Authentication with Eryph API"
  puts "• Reading projects, catlets, and operations"
  puts
  puts "Note: Using system-client with read-only permissions."
  puts "      Write operations require user credentials."
  puts

  # Create client with automatic credential discovery
  client = create_client

  # Test connection and display client info
  test_connection(client)

  # Demonstrate basic API operations
  demonstrate_api_operations(client)

  puts "\nExample completed successfully!"
  puts "Try exploring other demos: catlet_management.rb, zero_detection.rb"
end

def create_client
  puts 'Creating compute client...'
  puts '• Using automatic credential discovery'
  puts '• Requesting compute:write scope (read operations)'
  puts '• SSL verification disabled for local development'

  # Automatic discovery finds the best available credentials
  client = Eryph.compute_client(ssl_config: { verify_ssl: false },
                                scopes: ['compute:write'])

  # Alternative creation methods:
  # Eryph.compute_client('zero')                    # specific configuration
  # Eryph.compute_client(client_id: 'my-client')    # specific client ID

  puts "✓ Using configuration: #{client.config_name}"
  puts "✓ Endpoint: #{client.compute_endpoint_url}"
  client
end

def test_connection(client)
  puts 'Testing connection...'

  if client.test_connection
    puts "Connected successfully to #{client.config_name} configuration"
    display_client_info(client)
  else
    puts 'Connection failed'
    exit 1
  end
end

def display_client_info(client)
  token_provider = client.instance_variable_get(:@token_provider)
  puts "Token endpoint: #{token_provider.credentials.token_endpoint}"

  token_preview = "#{client.access_token[0..20]}..."
  puts "Access token: #{token_preview}"
end

def demonstrate_api_operations(client)
  puts "\nDemonstrating API operations..."

  list_projects(client)
  list_catlets(client)
  list_recent_operations(client)
end

def list_projects(client)
  puts "\n1. Listing Projects"
  puts "   " + "=" * 20

  projects = client.projects.projects_list
  project_list = projects.respond_to?(:value) ? projects.value : projects

  if project_list.empty?
    puts "   No projects found"
    return
  end

  project_list.each_with_index do |project, index|
    puts "   #{index + 1}. #{project.name}"
    puts "      ID: #{project.id}"
    puts "      Tenant: #{project.tenant_id}" if project.respond_to?(:tenant_id)
  end
rescue StandardError => e
  puts "   Error: #{e.message}"
end

def list_catlets(client)
  puts "\n2. Listing Catlets (Virtual Machines)"
  puts "   " + "=" * 35

  catlets = client.catlets.catlets_list
  catlet_list = catlets.respond_to?(:value) ? catlets.value : catlets

  if catlet_list.empty?
    puts "   No catlets found"
    return
  end

  catlet_list.each_with_index do |catlet, index|
    puts "   #{index + 1}. #{catlet.name}"
    puts "      Status: #{catlet.status}"
    puts "      ID: #{catlet.id}"
    
    if catlet.respond_to?(:networks) && catlet.networks&.any?
      puts "      Networks:"
      catlet.networks.each do |network|
        ip_info = network.respond_to?(:ip_v4_addresses) && network.ip_v4_addresses&.any? ? 
                  " (#{network.ip_v4_addresses.join(', ')})" : ""
        puts "        - #{network.name}#{ip_info}"
      end
    end
    puts
  end
rescue StandardError => e
  puts "   Error: #{e.message}"
end

def list_recent_operations(client)
  puts "\n3. Recent Operations"
  puts "   " + "=" * 20

  operations = client.operations.operations_list
  operation_list = operations.respond_to?(:value) ? operations.value : operations

  if operation_list.empty?
    puts "   No recent operations found"
    return
  end

  # Show only first 5 operations to keep output manageable
  recent_operations = operation_list.first(5)
  
  recent_operations.each_with_index do |operation, index|
    puts "   #{index + 1}. #{operation.id}"
    puts "      Status: #{operation.status}"
    puts "      Message: #{operation.status_message}" if operation.respond_to?(:status_message) && !operation.status_message.empty?
    puts
  end

  total_count = operation_list.length
  if total_count > 5
    puts "   ... and #{total_count - 5} more operations"
  end
rescue StandardError => e
  puts "   Error: #{e.message}"
end

# Error handling
begin
  main
rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts "Credentials not found: #{e.message}"
  puts 'Please set up configuration files in your .eryph directory'
  puts "Run 'Eryph.credentials_available?' to test availability"
  exit 1
rescue Eryph::ClientRuntime::TokenRequestError => e
  puts "Authentication failed: #{e.message}"
  puts 'Check your client credentials and network connectivity'
  exit 1
rescue Eryph::Compute::ApiError => e
  puts "API Error: #{e.message}"
  puts "Response Code: #{e.code}" if e.respond_to?(:code)
  puts "Response Body: #{e.response_body}" if e.respond_to?(:response_body)
  exit 1
rescue StandardError => e
  puts "Unexpected error: #{e.message}"
  puts e.backtrace if ENV['DEBUG']
  exit 1
end
