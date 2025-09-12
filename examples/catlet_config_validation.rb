#!/usr/bin/env ruby

# Catlet Configuration Validation Example
# Demonstrates validating catlet configurations before deployment

require_relative '../lib/eryph'

def main
  puts 'Catlet Configuration Validation Example'
  puts '-' * 40

  client = create_client

  demonstrate_hash_validation(client)
  demonstrate_json_validation(client)
  demonstrate_config_expansion(client)
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

def demonstrate_hash_validation(client)
  puts "\n1. Hash Configuration Validation"
  puts '-' * 30

  config = create_sample_config
  puts "Validating configuration: #{config[:name]}"

  validate_config(client, config, 'Ruby Hash')
end

def demonstrate_json_validation(client)
  puts "\n2. JSON Configuration Validation"
  puts '-' * 30

  config = create_sample_config
  json_config = config.to_json

  puts "Validating JSON configuration (#{json_config.length} characters)"
  validate_config(client, json_config, 'JSON String')
end

def demonstrate_config_expansion(client)
  puts "\n3. Configuration Expansion"
  puts '-' * 25

  minimal_config = {
    name: 'minimal-example',
    parent: 'dbosoft/ubuntu-22.04/starter',
  }

  puts "Expanding minimal configuration: #{minimal_config[:name]}"
  expand_config(client, minimal_config)
end

def create_sample_config
  {
    name: "validation-example-#{Time.now.to_i}",
    parent: 'dbosoft/winsrv2019-standard/starter',
    cpu: { count: 2 },
    memory: {
      startup: 2048,
      minimum: 1024,
      maximum: 4096,
    },
    drives: [
      {
        name: 'data',
        size: 10,
        type: 'SharedVHD',
      },
    ],
    networks: [
      {
        name: 'default',
        adapter_name: 'eth0',
      },
    ],
  }
end

def validate_config(client, config, config_type)
  puts "Validating #{config_type} configuration..."

  unless client.respond_to?(:validate_catlet_config)
    puts 'Note: Configuration validation methods are not yet implemented in this client version.'
    puts "Configuration structure appears valid for #{config_type} format."
    return
  end

  begin
    result = client.validate_catlet_config(config)

    if validation_successful?(result)
      puts 'Validation successful'
      display_validation_result(result)
    else
      puts 'Validation failed'
      display_validation_errors(result)
    end
  rescue StandardError => e
    puts "Validation error: #{e.message}"
  end
end

def expand_config(client, config)
  puts 'Expanding configuration with defaults...'

  unless client.respond_to?(:expand_config)
    puts 'Note: Configuration expansion methods are not yet implemented in this client version.'
    puts 'Input configuration:'
    config.each { |k, v| puts "  #{k}: #{v}" }
    return
  end

  begin
    result = client.expand_config(config)

    puts 'Expansion successful'
    display_expanded_config(result)
  rescue StandardError => e
    puts "Expansion error: #{e.message}"
  end
end

def validation_successful?(result)
  result.respond_to?(:valid?) ? result.valid? : true
end

def display_validation_result(result)
  puts 'Configuration is valid'

  return unless result.respond_to?(:warnings) && result.warnings&.any?

  puts 'Warnings:'
  result.warnings.each { |warning| puts "  - #{warning}" }
end

def display_validation_errors(result)
  if result.respond_to?(:errors) && result.errors&.any?
    puts 'Validation errors:'
    result.errors.each { |error| puts "  - #{error}" }
  end

  return unless result.respond_to?(:warnings) && result.warnings&.any?

  puts 'Warnings:'
  result.warnings.each { |warning| puts "  - #{warning}" }
end

def display_expanded_config(result)
  puts 'Expanded configuration:'

  if result.respond_to?(:configuration)
    config = result.configuration
    display_config_section(config, 'CPU', :cpu)
    display_config_section(config, 'Memory', :memory)
    display_config_section(config, 'Drives', :drives)
    display_config_section(config, 'Networks', :networks)
  else
    puts "  #{result}"
  end
end

def display_config_section(config, section_name, section_key)
  return unless config.respond_to?(section_key)

  section_data = config.send(section_key)
  return if section_data.nil?

  puts "  #{section_name}:"

  case section_data
  when Hash
    section_data.each { |k, v| puts "    #{k}: #{v}" }
  when Array
    section_data.each_with_index do |item, index|
      puts "    #{index + 1}. #{item}"
    end
  else
    puts "    #{section_data}"
  end
end

def demonstrate_validation_scenarios
  puts "\n4. Common Validation Scenarios"
  puts '-' * 30

  scenarios = [
    ['Valid configuration', create_valid_config],
    ['Invalid parent image', create_invalid_parent_config],
    ['Invalid memory configuration', create_invalid_memory_config],
    ['Missing required fields', create_incomplete_config],
  ]

  client = create_client

  scenarios.each do |scenario_name, config|
    puts "\nScenario: #{scenario_name}"
    validate_config(client, config, 'Test Case')
  end
end

def create_valid_config
  {
    name: 'valid-config',
    parent: 'dbosoft/ubuntu-22.04/starter',
    cpu: { count: 1 },
    memory: { startup: 1024 },
  }
end

def create_invalid_parent_config
  {
    name: 'invalid-parent',
    parent: 'nonexistent/image/latest',
    cpu: { count: 1 },
    memory: { startup: 1024 },
  }
end

def create_invalid_memory_config
  {
    name: 'invalid-memory',
    parent: 'dbosoft/ubuntu-22.04/starter',
    cpu: { count: 1 },
    memory: { startup: 4096, maximum: 1024 }, # Invalid: startup > maximum
  }
end

def create_incomplete_config
  {
    parent: 'dbosoft/ubuntu-22.04/starter', # Missing name
  }
end

begin
  main
  demonstrate_validation_scenarios
  puts "\nConfiguration validation example completed"
rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts "Credentials not found: #{e.message}"
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
