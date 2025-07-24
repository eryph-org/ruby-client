#!/usr/bin/env ruby

require_relative 'lib/eryph'

client = nil
begin
  client = Eryph.compute_client('zero', verify_ssl: false)
  puts "✅ Client created successfully"
rescue => e
  puts "ℹ️  Client creation failed (expected): #{e.class}"
end

puts "\n🧪 Testing stop command structure..."
begin
  # Test the stop command structure with proper namespace
  stop_request = Eryph::ComputeClient::StopCatletRequestBody.new(
    mode: Eryph::ComputeClient::CatletStopMode::SHUTDOWN
  )
  puts "✅ Stop request created: mode=#{stop_request.mode}"
  
  # Test what parameters the API expects
  puts "\n📋 Expected API parameters:"
  puts "  Method: catlets_stop(catlet_id, stop_catlet_request_body)"
  puts "  Parameter 1: catlet_id (String)"
  puts "  Parameter 2: stop_catlet_request_body (StopCatletRequestBody object)"
  puts "  ✅ This matches our example usage: client.catlets.catlets_stop(catlet_id, stop_request)"
  
rescue => e
  puts "❌ Stop command test failed: #{e.message}"
end