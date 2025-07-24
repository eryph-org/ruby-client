#!/usr/bin/env ruby

require_relative 'lib/eryph'

client = Eryph.compute_client('zero', verify_ssl: false)

puts 'Testing catlets API...'
begin
  catlets = client.catlets.catlets_list
  puts "✅ Catlets list successful: #{catlets.class}"
  puts "   Found #{catlets.value.size} catlets"
  
  catlets.value.each do |c|
    puts "   - #{c.id}: #{c.name} (#{c.status})"
  end
  
  # Test getting a specific catlet if any exist
  if catlets.value.any?
    test_catlet = catlets.value.first
    puts "\nTesting specific catlet retrieval: #{test_catlet.id}"
    
    specific_catlet = client.catlets.catlets_get(test_catlet.id)
    puts "✅ Specific catlet retrieval successful: #{specific_catlet.name}"
  end
rescue => e
  puts "❌ Catlets API test failed: #{e.message[0..100]}"
end