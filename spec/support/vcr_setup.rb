require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.default_cassette_options = { 
    record: :once,
    match_requests_on: [:method, :uri, :headers, :body]
  }
  
  # Configure sensitive data filtering
  config.filter_sensitive_data('<ACCESS_TOKEN>') do |interaction|
    if interaction.response.headers['content-type']&.first&.include?('application/json')
      begin
        body = JSON.parse(interaction.response.body)
        body['access_token'] if body.is_a?(Hash)
      rescue JSON::ParserError
        nil
      end
    end
  end
  
  config.filter_sensitive_data('<BEARER_TOKEN>') do |interaction|
    auth_header = interaction.request.headers['Authorization']&.first
    if auth_header&.start_with?('Bearer ')
      auth_header.split(' ').last
    end
  end
  
  config.filter_sensitive_data('<CLIENT_ID>') do |interaction|
    if interaction.request.body&.include?('client_id=')
      URI.decode_www_form(interaction.request.body).to_h['client_id']
    end
  end
  
  config.filter_sensitive_data('<JWT_ASSERTION>') do |interaction|
    if interaction.request.body&.include?('client_assertion=')
      URI.decode_www_form(interaction.request.body).to_h['client_assertion']
    end
  end
  
  # Allow real HTTP for localhost (eryph-zero) during development
  config.ignore_localhost = false
  config.ignore_hosts 'localhost', '127.0.0.1' if ENV['VCR_IGNORE_LOCALHOST']
  
  # Configure for different record modes
  config.default_cassette_options[:record] = :new_episodes if ENV['VCR_RECORD_NEW']
  config.default_cassette_options[:record] = :all if ENV['VCR_RECORD_ALL']
end