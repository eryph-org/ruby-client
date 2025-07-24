#!/usr/bin/env ruby

require_relative 'lib/eryph'

client = Eryph.compute_client('zero', verify_ssl: false)

# Get the first catlet to see its properties
catlets = client.catlets.catlets_list
if catlets.value.any?
  catlet = catlets.value.first
  puts "Catlet properties for #{catlet.name}:"
  catlet.instance_variables.each do |var|
    value = catlet.instance_variable_get(var)
    puts "  #{var}: #{value.class} = #{value}"
  end
  
  puts "\nMethods containing 'cpu' or 'memory':"
  catlet.methods.grep(/cpu|memory/).each { |m| puts "  #{m}" }
end