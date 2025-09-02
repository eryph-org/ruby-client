require 'webmock/rspec'

# Configure WebMock for unit tests
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    'raw.githubusercontent.com', # Allow OpenAPI spec downloads during tests
  ]
)

# Helper methods for common HTTP mocks
module WebMockHelpers
  def stub_token_request(endpoint:, response: {})
    default_response = {
      access_token: 'test_access_token',
      token_type: 'Bearer',
      expires_in: 3600,
      scope: 'compute:read compute:write',
    }

    stub_request(:post, endpoint)
      .with(
        body: hash_including(
          'grant_type' => 'client_credentials',
          'client_assertion_type' => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        ),
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
        }
      )
      .to_return(
        status: 200,
        body: default_response.merge(response).to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_token_error(endpoint:, error_code: 'invalid_client', status: 400)
    stub_request(:post, endpoint)
      .to_return(
        status: status,
        body: {
          error: error_code,
          error_description: 'Authentication failed',
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_api_request(method:, path:, response: {}, status: 200)
    default_response = { value: [] }

    stub_request(method, %r{/compute#{path}})
      .with(headers: { 'Authorization' => /Bearer/ })
      .to_return(
        status: status,
        body: default_response.merge(response).to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_catlets_list(catlets: [])
    stub_api_request(
      method: :get,
      path: '/v1/catlets',
      response: { value: catlets }
    )
  end

  def stub_projects_list(projects: [])
    stub_api_request(
      method: :get,
      path: '/v1/projects',
      response: { value: projects }
    )
  end
end

RSpec.configure do |config|
  config.include WebMockHelpers
end
