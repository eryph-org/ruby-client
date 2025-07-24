#!/usr/bin/env ruby

require_relative 'lib/eryph'

client = Eryph.compute_client('zero', verify_ssl: false)

puts '🐱 Testing catlet creation and operation retrieval...'

# Create a catlet with proper request structure
catlet_config = {
  name: "example-catlet-#{Time.now.to_i}",
  parent: "dbosoft/winsrv2019-standard/starter",
  cpu: { count: 2 },
  memory: { startup: 2048, minimum: 1024, maximum: 4096 }
}

puts "Creating catlet: #{catlet_config[:name]}"

# Use the proper generated client class
create_request = ComputeClient::NewCatletRequest.new(configuration: catlet_config)
operation = client.catlets.catlets_create(new_catlet_request: create_request)
puts "Operation created: #{operation.id}"

# Check if operation appears in the list
puts "Checking operations list immediately after creation..."
begin
  operations_list = client.operations.operations_list
  puts "Operations list successful, found #{operations_list.value.size} operations"
  
  found_operation = operations_list.value.find { |op| op.id == operation.id }
  if found_operation
    puts "✅ Operation found in list: #{found_operation.status}"
    
    # Now try to get it directly
    puts "Trying direct retrieval since it's in the list..."
    specific_op = client.operations.operations_get(operation.id)
    puts "✅ Direct retrieval successful: #{specific_op.status}"
  else
    puts "❌ Operation not found in operations list"
  end
rescue => e
  puts "❌ Operations list failed: #{e.message[0..100]}"
end