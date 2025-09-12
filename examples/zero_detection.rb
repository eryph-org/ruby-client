#!/usr/bin/env ruby

# Eryph-Zero Detection Example
# Demonstrates automatic discovery of running eryph-zero instances
# and system credential usage

require_relative '../lib/eryph'

def main
  puts 'Eryph-Zero Detection Example'
  puts '-' * 30

  detect_zero_instance
  test_zero_credentials
  create_zero_client if zero_available?
end

def detect_zero_instance
  puts 'Checking for running eryph-zero instance...'

  if Eryph.zero_running?
    puts 'Eryph-zero is running'
    display_endpoints
  else
    puts 'Eryph-zero is not running or not detected'
    puts 'Make sure eryph-zero is started and accessible'
  end
end

def display_endpoints
  puts 'Discovered endpoints:'

  endpoints = Eryph.zero_endpoints
  endpoints.each do |name, url|
    puts "  #{name.capitalize}: #{url}"
  end
end

def test_zero_credentials
  puts 'Testing zero credential availability...'

  if Eryph.credentials_available?('zero')
    puts 'Zero credentials are available (using system-client)'
  else
    puts 'Zero credentials are not available'
    puts 'Eryph-zero may not be configured for client access'
  end
end

def zero_available?
  Eryph.zero_running? && Eryph.credentials_available?('zero')
end

def create_zero_client
  puts 'Creating client for eryph-zero...'

  begin
    client = Eryph.compute_client('zero',
                                  ssl_config: { verify_ssl: false },
                                  scopes: ['compute:write'])
    zero_connection_working?(client)
    demonstrate_zero_operations(client)
  rescue StandardError => e
    puts "Failed to create zero client: #{e.message}"
  end
end

def zero_connection_working?(client)
  puts 'Testing zero client connection...'

  if client.test_connection
    puts 'Connected successfully to eryph-zero'
    display_zero_client_info(client)
  else
    puts 'Connection to eryph-zero failed'
    return false
  end

  true
end

def display_zero_client_info(client)
  token_provider = client.instance_variable_get(:@token_provider)
  puts "Configuration: #{client.config_name}"
  puts "Identity endpoint: #{token_provider.credentials.token_endpoint}"
end

def demonstrate_zero_operations(client)
  puts 'Testing basic operations against eryph-zero...'

  operations = %w[projects catlets operations]

  operations.each do |operation|
    test_operation(client, operation)
  end
end

def test_operation(client, operation)
  puts "Testing #{operation} endpoint..."

  response = client.send(operation).send("#{operation}_list")
  puts "#{operation.capitalize} response received: #{response.class}"
rescue StandardError => e
  puts "Error with #{operation} endpoint: #{e.message}"
end

begin
  main
  puts "\nZero detection example completed"
rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts "Credentials error: #{e.message}"
  puts 'Ensure eryph-zero is running and configured for client access'
rescue Eryph::ClientRuntime::TokenRequestError => e
  puts "Authentication error: #{e.message}"
  puts 'Check eryph-zero configuration and network connectivity'
rescue StandardError => e
  puts "Unexpected error: #{e.message}"
  puts e.backtrace if ENV['DEBUG']
  exit 1
end
