#!/usr/bin/env ruby

# Simple test script to demonstrate debug logging in credential lookup
require 'bundler/setup'
require 'eryph'
require 'logger'

# Create a debug logger
logger = Logger.new($stdout)
logger.level = Logger::DEBUG
logger.formatter = proc do |severity, datetime, progname, msg|
  "[#{severity}] #{msg}\n"
end

puts "🔍 Testing DEBUG logging for credential lookup"
puts "=" * 50
puts

CONFIG_NAME = ENV['ERYPH_CONFIG'] || 'zero'

begin
  puts "Configuration: #{CONFIG_NAME}"
  puts

  # Test with debug logging enabled
  client_options = {
    logger: logger,
    scopes: %w[compute:write]
  }
  
  # For eryph-zero, disable SSL verification 
  if CONFIG_NAME == 'zero'
    client_options[:ssl_config] = { verify_ssl: false }
  end

  puts "Creating compute client with DEBUG logging..."
  puts
  
  client = Eryph.compute_client(CONFIG_NAME, **client_options)
  
  puts
  puts "✅ Client created successfully!"
  puts "   Endpoint: #{client.compute_endpoint_url}"
  puts "   Config: #{client.config_name}"

rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts
  puts "❌ Credentials Error: #{e.message}"
  puts
  puts "The debug messages above show the credential lookup flow."

rescue => e
  puts
  puts "❌ Error: #{e.class}: #{e.message}"
  puts "Backtrace:"
  e.backtrace.first(3).each { |line| puts "   #{line}" }
end