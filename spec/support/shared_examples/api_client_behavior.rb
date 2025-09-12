RSpec.shared_examples 'an authenticated API client' do
  it 'includes authorization header in requests' do
    expect(subject.api_client.config.access_token).to be_present
  end

  it 'uses correct base URL' do
    expect(subject.api_client.config.base_url).to match(%r{/compute$})
  end

  it 'has proper SSL configuration' do
    config = subject.api_client.config

    # Default SSL settings should be secure
    expect(config.verify_ssl).to be_truthy unless explicitly_disabled_ssl?
    expect(config.ssl_verify_mode).to be_present
  end

  private

  def explicitly_disabled_ssl?
    # Check if SSL was explicitly disabled in test setup
    subject.instance_variable_get(:@ssl_config)&.dig(:verify_ssl) == false
  end
end

RSpec.shared_examples 'a paginated API response' do |expected_type|
  it 'returns the expected response type' do
    expect(subject).to be_a(expected_type)
  end

  it 'has a value array' do
    expect(subject.value).to be_an(Array)
  end

  it 'responds to pagination methods' do
    expect(subject).to respond_to(:value)
  end
end

RSpec.shared_examples 'an API error handler' do
  context 'when API returns an error' do
    before do
      stub_request(:any, /.*/)
        .to_return(
          status: 400,
          body: { error: 'Bad Request', message: 'Invalid parameters' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'raises appropriate error' do
      expect { subject }.to raise_error(Eryph::ComputeClient::ApiError)
    end
  end

  context 'when authentication fails' do
    before do
      stub_request(:any, /.*/)
        .to_return(status: 401, body: 'Unauthorized')
    end

    it 'raises authentication error' do
      expect { subject }.to raise_error(Eryph::ComputeClient::ApiError, /401/)
    end
  end

  context 'when server is unavailable' do
    before do
      stub_request(:any, /.*/).to_timeout
    end

    it 'raises connection error' do
      expect { subject }.to raise_error
    end
  end
end

RSpec.shared_examples 'a configuration-based client' do
  it 'uses provided configuration name' do
    expect(subject.config_name).to eq(config_name)
  end

  it 'has credentials lookup configured' do
    credentials_lookup = subject.instance_variable_get(:@credentials_lookup)
    expect(credentials_lookup).to be_present
  end

  it 'has token provider configured' do
    expect(subject.token_provider).to be_a(Eryph::ClientRuntime::TokenProvider)
  end
end

RSpec.shared_examples 'SSL configuration support' do
  context 'with SSL verification disabled' do
    let(:ssl_config) { { verify_ssl: false } }

    it 'disables SSL verification' do
      client_ssl_config = subject.instance_variable_get(:@ssl_config)
      expect(client_ssl_config[:verify_ssl]).to be false
    end
  end

  context 'with custom CA certificate' do
    let(:ssl_config) { { ca_file: '/path/to/ca.crt' } }

    it 'uses custom CA certificate' do
      client_ssl_config = subject.instance_variable_get(:@ssl_config)
      expect(client_ssl_config[:ca_file]).to eq('/path/to/ca.crt')
    end
  end
end
