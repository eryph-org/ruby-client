#!/usr/bin/env ruby

# Catlet Management Example
# Demonstrates creating, listing, and managing catlets (virtual machines)

require_relative '../lib/eryph'

CATLET_CONFIG = {
  name: "ruby-example-#{Time.now.to_i}",
  parent: 'dbosoft/ubuntu-22.04/starter',
  cpu: { count: 1 },
  memory: { startup: 1024 }
}.freeze

def main
  puts 'Catlet Management Example'
  puts '=' * 25

  client = create_client
  test_api_connectivity(client)

  puts "\nThis demo will create, manage, and clean up a test catlet."
  
  catlet_info = create_catlet(client)
  return unless catlet_info

  list_catlets(client)
  demonstrate_catlet_inspection(client, catlet_info)
  
  cleanup_catlet(client, catlet_info)
end

def create_client
  puts 'Creating compute client...'

  client = Eryph.compute_client(ssl_config: { verify_ssl: false },
                                scopes: ['compute:write'])
  puts "Using configuration: #{client.config_name}"
  puts "Compute endpoint: #{client.compute_endpoint_url}"

  client
end

def test_api_connectivity(client)
  puts 'Testing API connectivity...'

  if client.test_connection
    puts 'Successfully connected to compute API'
  else
    puts 'Connection test failed'
    exit 1
  end
rescue StandardError => e
  puts "Connection test failed: #{e.message}"
  exit 1
end

def create_catlet(client)
  puts "\nCreating new catlet..."
  puts "Configuration: #{CATLET_CONFIG}"

  begin
    request = Eryph::ComputeClient::NewCatletRequest.new(configuration: CATLET_CONFIG)
    operation = client.catlets.catlets_create(new_catlet_request: request)

    puts "Catlet creation initiated (Operation: #{operation.id})"

    # Wait for creation to complete
    puts "Waiting for catlet creation to complete..."
    completed_operation = client.wait_for_operation(operation.id, timeout: 600)

    if completed_operation.status == 'Completed'
      puts "✓ Catlet created successfully!"
      
      # Get the created catlet information from the operation
      if completed_operation.respond_to?(:resources) && completed_operation.resources&.any?
        catlet_resource = completed_operation.resources.find { |r| r.resource_type == 'Catlet' }
        if catlet_resource
          { 
            id: catlet_resource.resource_id,
            name: CATLET_CONFIG[:name]
          }
        else
          # Fallback: return name to lookup catlet
          { name: CATLET_CONFIG[:name] }
        end
      else
        # Fallback: return name to lookup catlet
        { name: CATLET_CONFIG[:name] }
      end
    else
      puts "✗ Catlet creation failed: #{completed_operation.status_message}"
      nil
    end
  rescue StandardError => e
    puts "Error creating catlet: #{e.message}"
    nil
  end
end

def demonstrate_catlet_inspection(client, catlet_info)
  catlet_identifier = catlet_info.is_a?(Hash) ? (catlet_info[:id] || catlet_info[:name]) : catlet_info
  puts "\nInspecting the created catlet: #{catlet_identifier}"
  
  begin
    catlet = client.catlets.catlets_get(catlet_identifier)
    
    puts "  ID: #{catlet.id}"
    puts "  Status: #{catlet.status}"
    puts "  VM ID: #{catlet.vm_id}" if catlet.respond_to?(:vm_id)
    
    if catlet.respond_to?(:networks) && catlet.networks&.any?
      puts "  Networks:"
      catlet.networks.each do |network|
        ip_info = network.respond_to?(:ip_v4_addresses) && network.ip_v4_addresses&.any? ? 
                  network.ip_v4_addresses.join(', ') : 'No IP assigned yet'
        puts "    - #{network.name}: #{ip_info}"
      end
    end

    if catlet.respond_to?(:drives) && catlet.drives&.any?
      puts "  Drives: #{catlet.drives.length} drive(s)"
    end
    
  rescue StandardError => e
    puts "Error inspecting catlet: #{e.message}"
  end
end

def cleanup_catlet(client, catlet_info)
  catlet_identifier = catlet_info.is_a?(Hash) ? (catlet_info[:id] || catlet_info[:name]) : catlet_info
  puts "\nCleaning up test catlet: #{catlet_identifier}"
  
  begin
    operation = client.catlets.catlets_delete(catlet_identifier)
    puts "Catlet deletion initiated (Operation: #{operation.id})"
    
    # Wait for deletion to complete
    puts "Waiting for catlet deletion to complete..."
    completed_operation = client.wait_for_operation(operation.id, timeout: 300)
    
    if completed_operation.status == 'Completed'
      puts "✓ Test catlet deleted successfully!"
    else
      puts "✗ Catlet deletion failed: #{completed_operation.status_message}"
    end
  rescue StandardError => e
    puts "Warning: Could not delete test catlet: #{e.message}"
  end
end

def list_catlets(client)
  puts 'Listing existing catlets...'

  catlets = client.catlets.catlets_list
  catlet_list = catlets.respond_to?(:value) ? catlets.value : catlets

  if catlet_list.nil? || (catlet_list.respond_to?(:empty?) && catlet_list.empty?)
    puts 'No catlets found'
    return
  end

  display_catlets(catlets)
rescue StandardError => e
  puts "Error listing catlets: #{e.message}"
end

def display_catlets(catlets)
  catlet_list = catlets.respond_to?(:value) ? catlets.value : catlets

  return puts 'No catlet data available' if catlet_list.nil?

  catlet_list.each_with_index do |catlet, index|
    puts "#{index + 1}. #{catlet.name || 'Unnamed'}"
    puts "   Status: #{catlet.status || 'Unknown'}"
    puts "   Agent: #{catlet.agent || 'None'}" if catlet.respond_to?(:agent)
    display_catlet_networks(catlet) if catlet.respond_to?(:networks)
  end
end

def display_catlet_networks(catlet)
  return unless catlet.networks&.any?

  puts '   Networks:'
  catlet.networks.each do |network|
    network_info = network.name.to_s
    if network.respond_to?(:ip_v4_addresses) && network.ip_v4_addresses&.any?
      network_info += ": #{network.ip_v4_addresses.join(', ')}"
    end
    puts "     - #{network_info}"
  end
end



begin
  main
  puts "\nCatlet management example completed"
rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts "Credentials not found: #{e.message}"
  puts 'Please configure eryph-zero or set up client credentials'
  exit 1
rescue Eryph::ClientRuntime::TokenRequestError => e
  puts "Authentication failed: #{e.message}"
  puts 'Check your client credentials and eryph-zero configuration'
  exit 1
rescue Eryph::Compute::ApiError => e
  puts "API Error: #{e.message}"
  puts "Response Code: #{e.code}" if e.respond_to?(:code)
  exit 1
rescue StandardError => e
  puts "Unexpected error: #{e.message}"
  puts e.backtrace if ENV['DEBUG']
  exit 1
end
