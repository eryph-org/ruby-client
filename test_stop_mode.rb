#!/usr/bin/env ruby

require_relative 'lib/eryph'

puts 'Testing stop mode constant...'
begin
  stop_request = ComputeClient::StopCatletRequestBody.new(
    mode: ComputeClient::CatletStopMode::SHUTDOWN
  )
  puts "✅ Stop request created successfully"
  puts "Mode: #{stop_request.mode}"
rescue => e
  puts "❌ Failed to create stop request: #{e.message}"
end