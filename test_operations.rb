#!/usr/bin/env ruby

require_relative 'lib/eryph'

client = Eryph.compute_client('zero', verify_ssl: false)

puts 'Testing operations API...'
operations_list = client.operations.operations_list(expand: 'logs,tasks')
puts "Operations list object: #{operations_list.class}"
puts "Available methods: #{operations_list.methods.grep(/operation/).sort}"

# Try different property names
if operations_list.respond_to?(:value)
  puts "Has value property with #{operations_list.value.size} items"
  operations_list.value.each_with_index do |op, i|
    puts "  #{i+1}. #{op.id} - #{op.status}"
    break if i >= 2
  end
elsif operations_list.respond_to?(:data)
  puts "Has data property: #{operations_list.data.class}"
else
  puts "Exploring object structure..."
  operations_list.instance_variables.each do |var|
    puts "  #{var}: #{operations_list.instance_variable_get(var).class}"
  end
end