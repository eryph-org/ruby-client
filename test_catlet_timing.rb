#!/usr/bin/env ruby

require_relative 'lib/eryph'

client = Eryph.compute_client('zero', verify_ssl: false)

puts '🐱 Testing catlet creation timing...'

# Create a catlet with proper request structure
catlet_config = {
  name: "timing-test-catlet-#{Time.now.to_i}",
  parent: "dbosoft/winsrv2019-standard/starter",
  cpu: { count: 2 },
  memory: { startup: 2048, minimum: 1024, maximum: 4096 }
}

puts "Creating catlet: #{catlet_config[:name]}"

# Use the proper generated client class
create_request = ComputeClient::NewCatletRequest.new(configuration: catlet_config)
operation = client.catlets.catlets_create(new_catlet_request: create_request)
puts "Operation created: #{operation.id}"

# Wait for the operation to complete
puts "Waiting for operation to complete..."
completed_operation = client.wait_for_operation(operation.id)
puts "Operation completed with status: #{completed_operation.status}"

if completed_operation.resources && !completed_operation.resources.empty?
  catlet_id = completed_operation.resources.first.id
  puts "Got catlet ID from operation: #{catlet_id}"
  
  # Check if it's in the catlets list
  puts "Checking if catlet appears in list..."
  catlets = client.catlets.catlets_list
  found_in_list = catlets.value.find { |c| c.id == catlet_id }
  
  if found_in_list
    puts "✅ Catlet found in list: #{found_in_list.name} (#{found_in_list.status})"
    
    # Try to get it directly
    puts "Trying direct retrieval..."
    begin
      direct_catlet = client.catlets.catlets_get(catlet_id)
      puts "✅ Direct retrieval successful: #{direct_catlet.name} (#{direct_catlet.status})"
    rescue => e
      puts "❌ Direct retrieval failed: #{e.message[0..100]}"
    end
  else
    puts "❌ Catlet not found in list"
    puts "Available catlets:"
    catlets.value.each { |c| puts "  - #{c.id}: #{c.name}" }
  end
else
  puts "❌ No resources found in completed operation"
end