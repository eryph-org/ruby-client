#!/usr/bin/env ruby

require_relative 'lib/eryph'

client = Eryph.compute_client('zero', verify_ssl: false)

# Get the first catlet and its details
catlets = client.catlets.catlets_list
if catlets.value.any?
  catlet_id = catlets.value.first.id
  puts "Getting detailed catlet info for: #{catlet_id}"
  
  detailed_catlet = client.catlets.catlets_get(catlet_id)
  puts "\nDetailed catlet properties:"
  detailed_catlet.instance_variables.each do |var|
    value = detailed_catlet.instance_variable_get(var)
    puts "  #{var}: #{value.class} = #{value}"
  end
  
  puts "\nAll methods:"
  detailed_catlet.methods.sort.each { |m| puts "  #{m}" }
end