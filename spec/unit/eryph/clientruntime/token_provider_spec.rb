require 'spec_helper'
require 'time'

RSpec.describe Eryph::ClientRuntime::TokenProvider do
  let(:credentials) { build(:credentials) }
  let(:token_provider) { described_class.new(credentials) }
  
  describe '#initialize' do
    it 'creates a token provider with credentials' do
      expect(token_provider.credentials).to eq(credentials)
    end
    
    it 'sets default scopes when none provided' do
      expect(token_provider.scopes).to include('compute:read', 'compute:write')
    end

    it 'accepts custom scopes' do
      custom_scopes = ['custom:read', 'custom:write']
      provider = described_class.new(credentials, scopes: custom_scopes)

      expect(provider.scopes).to eq(custom_scopes)
    end

    it 'merges custom HTTP config with defaults' do
      custom_config = { timeout: 120, verify_ssl: false }
      provider = described_class.new(credentials, http_config: custom_config)

      expect(provider.http_config[:timeout]).to eq(120)
      expect(provider.http_config[:verify_ssl]).to eq(false)
      expect(provider.http_config[:user_agent]).to include('eryph-ruby-clientruntime')
    end

    it 'initializes with nil current token' do
      expect(token_provider.current_token).to be_nil
    end
  end

  describe '#get_token' do
    let(:mock_response) { double('HTTPResponse') }
    let(:token_data) do
      {
        'access_token' => 'test_access_token',
        'token_type' => 'Bearer',
        'expires_in' => 3600,
        'scope' => 'compute:read compute:write'
      }.to_json
    end

    before do
      allow(token_provider).to receive(:make_token_request).and_return(mock_response)
      allow(mock_response).to receive(:body).and_return(token_data)
    end

    it 'returns a TokenResponse object' do
      result = token_provider.get_token

      expect(result).to be_a(Eryph::ClientRuntime::TokenResponse)
      expect(result.access_token).to eq('test_access_token')
      expect(result.token_type).to eq('Bearer')
      expect(result.expires_in).to eq(3600)
      expect(result.scopes).to eq(['compute:read', 'compute:write'])
    end

    it 'caches the token' do
      first_token = token_provider.get_token
      second_token = token_provider.get_token

      expect(first_token).to be(second_token)
      expect(token_provider).to have_received(:make_token_request).once
    end

    it 'refreshes expired token' do
      # Mock an expired token
      expired_token = double('TokenResponse', expired?: true)
      token_provider.instance_variable_set(:@current_token, expired_token)

      result = token_provider.get_token

      expect(result).not_to be(expired_token)
      expect(result.access_token).to eq('test_access_token')
    end

    it 'is thread-safe' do
      call_count = 0
      allow(token_provider).to receive(:request_new_token) do
        call_count += 1
        sleep(0.1) # Simulate slow token request
        Eryph::ClientRuntime::TokenResponse.new(
          access_token: "token_#{call_count}",
          expires_in: 3600
        )
      end

      threads = 10.times.map do
        Thread.new { token_provider.get_token }
      end

      tokens = threads.map(&:value)
      
      # All tokens should be the same (only one request made)
      expect(tokens.uniq.size).to eq(1)
      expect(call_count).to eq(1)
    end
  end

  describe '#get_access_token' do
    before do
      stub_token_request(endpoint: credentials.token_endpoint)
    end
    
    it 'returns an access token string' do
      token = token_provider.get_access_token
      expect(token).to eq('test_access_token')
    end

    it 'refreshes token when expired' do
      # Create expired token
      expired_token = Eryph::ClientRuntime::TokenResponse.new(
        access_token: 'old_token',
        expires_in: -1  # Already expired
      )
      token_provider.instance_variable_set(:@current_token, expired_token)

      token = token_provider.get_access_token

      expect(token).to eq('test_access_token')
      expect(token).not_to eq('old_token')
    end
  end

  describe '#access_token' do
    it 'returns nil when no token cached' do
      expect(token_provider.access_token).to be_nil
    end

    it 'returns cached token when not expired' do
      valid_token = Eryph::ClientRuntime::TokenResponse.new(
        access_token: 'cached_token',
        expires_in: 3600
      )
      token_provider.instance_variable_set(:@current_token, valid_token)

      token = token_provider.access_token

      expect(token).to eq('cached_token')
    end

    it 'refreshes expired token automatically' do
      stub_token_request(endpoint: credentials.token_endpoint)
      
      expired_token = Eryph::ClientRuntime::TokenResponse.new(
        access_token: 'expired_token',
        expires_in: -1
      )
      token_provider.instance_variable_set(:@current_token, expired_token)

      token = token_provider.access_token

      expect(token).to eq('test_access_token')
    end
  end

  describe '#refresh_token' do
    before do
      stub_token_request(endpoint: credentials.token_endpoint)
    end

    it 'forces token refresh and returns new token' do
      old_token = Eryph::ClientRuntime::TokenResponse.new(
        access_token: 'old_token',
        expires_in: 3600
      )
      token_provider.instance_variable_set(:@current_token, old_token)

      new_token = token_provider.refresh_token

      expect(new_token).to eq('test_access_token')
      expect(new_token).not_to eq('old_token')
    end

    it 'updates the cached token' do
      token_provider.refresh_token

      cached_token = token_provider.current_token
      expect(cached_token.access_token).to eq('test_access_token')
    end
  end

  describe '#authorization_header' do
    it 'returns nil when no token cached' do
      expect(token_provider.authorization_header).to be_nil
    end

    it 'returns authorization header for valid token' do
      valid_token = Eryph::ClientRuntime::TokenResponse.new(
        access_token: 'valid_token',
        token_type: 'Bearer',
        expires_in: 3600
      )
      token_provider.instance_variable_set(:@current_token, valid_token)

      header = token_provider.authorization_header

      expect(header).to eq('Bearer valid_token')
    end

    it 'returns nil for expired token' do
      expired_token = Eryph::ClientRuntime::TokenResponse.new(
        access_token: 'expired_token',
        expires_in: -1
      )
      token_provider.instance_variable_set(:@current_token, expired_token)

      header = token_provider.authorization_header

      expect(header).to be_nil
    end
  end

  describe '#create_client_assertion (private)' do
    let(:assertion) { token_provider.send(:create_client_assertion) }
    let(:decoded_claims) { JWT.decode(assertion, nil, false)[0] }

    it 'creates valid JWT with required claims' do
      expect(decoded_claims['iss']).to eq(credentials.client_id)
      expect(decoded_claims['sub']).to eq(credentials.client_id)
      expect(decoded_claims['aud']).to eq(credentials.token_endpoint)
      expect(decoded_claims['jti']).to be_a(String)
      expect(decoded_claims['iat']).to be_a(Integer)
      expect(decoded_claims['exp']).to be_a(Integer)
    end

    it 'sets expiration to 5 minutes from now' do
      now = Time.now.to_i
      expect(decoded_claims['exp']).to be_within(5).of(now + 300)
    end

    it 'can be verified with the private key' do
      public_key = OpenSSL::PKey::RSA.new(credentials.private_key).public_key

      expect {
        JWT.decode(assertion, public_key, true, { algorithm: 'RS256' })
      }.not_to raise_error
    end
  end

  describe '#make_token_request (private)' do
    let(:request_body) do
      {
        'grant_type' => 'client_credentials',
        'client_id' => credentials.client_id,
        'scope' => 'compute:read compute:write'
      }
    end

    before do
      stub_request(:post, credentials.token_endpoint)
        .to_return(status: 200, body: { access_token: 'test_token', expires_in: 3600 }.to_json)
    end

    it 'makes POST request to token endpoint' do
      token_provider.send(:make_token_request, request_body)

      expect(WebMock).to have_requested(:post, credentials.token_endpoint)
    end

    it 'sets correct headers' do
      token_provider.send(:make_token_request, request_body)

      expect(WebMock).to have_requested(:post, credentials.token_endpoint)
        .with(headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'User-Agent' => /eryph-ruby-clientruntime/
        })
    end

    it 'sends form-encoded body' do
      token_provider.send(:make_token_request, request_body)

      expect(WebMock).to have_requested(:post, credentials.token_endpoint)
        .with(body: /grant_type=client_credentials/)
    end

    context 'when request fails' do
      it 'raises TokenRequestError for HTTP error' do
        stub_request(:post, credentials.token_endpoint)
          .to_return(status: 400, body: { error: 'invalid_client' }.to_json)

        expect {
          token_provider.send(:make_token_request, request_body)
        }.to raise_error(Eryph::ClientRuntime::TokenRequestError, /invalid_client/)
      end

      it 'parses error response JSON' do
        stub_request(:post, credentials.token_endpoint)
          .to_return(
            status: 400, 
            body: { error: 'invalid_scope', error_description: 'Requested scope is invalid' }.to_json
          )

        expect {
          token_provider.send(:make_token_request, request_body)
        }.to raise_error(Eryph::ClientRuntime::TokenRequestError, /invalid_scope: Requested scope is invalid/)
      end

      it 'handles non-JSON error responses' do
        stub_request(:post, credentials.token_endpoint)
          .to_return(status: 500, body: 'Internal Server Error')

        expect {
          token_provider.send(:make_token_request, request_body)
        }.to raise_error(Eryph::ClientRuntime::TokenRequestError, /Internal Server Error/)
      end
    end
  end

  describe '#parse_token_response (private)' do
    let(:valid_response) do
      double('HTTPResponse', body: {
        'access_token' => 'parsed_token',
        'token_type' => 'Bearer',
        'expires_in' => 7200,
        'scope' => 'read write'
      }.to_json)
    end

    it 'parses valid token response' do
      result = token_provider.send(:parse_token_response, valid_response)

      expect(result).to be_a(Eryph::ClientRuntime::TokenResponse)
      expect(result.access_token).to eq('parsed_token')
      expect(result.token_type).to eq('Bearer')
      expect(result.expires_in).to eq(7200)
      expect(result.scopes).to eq(['read', 'write'])
    end

    it 'uses default values for missing fields' do
      minimal_response = double('HTTPResponse', body: {
        'access_token' => 'minimal_token'
      }.to_json)

      result = token_provider.send(:parse_token_response, minimal_response)

      expect(result.token_type).to eq('Bearer')
      expect(result.expires_in).to eq(3600)
      expect(result.scopes).to eq([])
    end

    it 'raises TokenRequestError for invalid JSON' do
      invalid_response = double('HTTPResponse', body: 'invalid json')

      expect {
        token_provider.send(:parse_token_response, invalid_response)
      }.to raise_error(Eryph::ClientRuntime::TokenRequestError, /Invalid JSON response/)
    end
  end

  describe 'HTTP configuration' do

    describe '#build_ssl_options (private)' do
      context 'when SSL verification enabled' do
        let(:provider) { described_class.new(credentials, http_config: { verify_ssl: true, verify_hostname: true }) }

        it 'enables SSL verification' do
          ssl_options = provider.send(:build_ssl_options)

          expect(ssl_options[:verify]).to be true
          expect(ssl_options[:verify_hostname]).to be true
        end

        it 'can disable hostname verification' do
          provider = described_class.new(credentials, http_config: { verify_ssl: true, verify_hostname: false })

          ssl_options = provider.send(:build_ssl_options)

          expect(ssl_options[:verify]).to be true
          expect(ssl_options[:verify_hostname]).to be false
        end

        it 'uses provided CA file' do
          ca_file = '/path/to/ca.pem'
          provider = described_class.new(credentials, http_config: { verify_ssl: true, ca_file: ca_file })

          ssl_options = provider.send(:build_ssl_options)

          expect(ssl_options[:ca_file]).to eq(ca_file)
        end

        it 'uses provided CA certificate' do
          ca_cert = OpenSSL::X509::Certificate.new
          provider = described_class.new(credentials, http_config: { verify_ssl: true, ca_cert: ca_cert })
          cert_store = double('OpenSSL::X509::Store')
          allow(OpenSSL::X509::Store).to receive(:new).and_return(cert_store)
          allow(cert_store).to receive(:add_cert)

          ssl_options = provider.send(:build_ssl_options)

          expect(ssl_options[:ca_cert]).to eq(ca_cert)
        end

        it 'sets default certificate paths when no custom CA provided' do
          cert_store = double('OpenSSL::X509::Store')
          allow(OpenSSL::X509::Store).to receive(:new).and_return(cert_store)
          allow(cert_store).to receive(:set_default_paths)
          
          # Override the defaults to test this specific path  
          provider = described_class.new(credentials, http_config: { 
            verify_ssl: true, 
            verify_hostname: true, 
            ca_cert: nil, 
            ca_file: nil, 
 
          })

          ssl_options = provider.send(:build_ssl_options)

          expect(ssl_options[:verify]).to be true
        end

      end

      context 'when SSL verification disabled' do
        let(:provider) { described_class.new(credentials, http_config: { verify_ssl: false }) }

        it 'disables SSL verification' do
          ssl_options = provider.send(:build_ssl_options)

          expect(ssl_options[:verify]).to be false
        end
      end

    end

  end

  describe 'error handling' do
    context 'when JWT signing fails' do
      before do
        allow(JWT).to receive(:encode).and_raise(JWT::EncodeError.new('Invalid key'))
      end

      it 'propagates JWT errors' do
        expect {
          token_provider.send(:create_client_assertion)
        }.to raise_error(JWT::EncodeError, 'Invalid key')
      end
    end

    context 'when network errors occur' do
      before do
        allow(token_provider).to receive(:make_token_request).and_raise(SocketError.new('Network unreachable'))
      end

      it 'propagates network errors' do
        expect {
          token_provider.get_access_token
        }.to raise_error(SocketError, 'Network unreachable')
      end
    end
  end

  describe 'logging' do
    let(:logger) { double('Logger') }
    let(:provider) { described_class.new(credentials, http_config: { logger: logger }) }

    before do
      allow(logger).to receive(:debug)
    end

    it 'logs debug messages when logger provided' do
      provider.send(:log_debug, 'Test message')

      expect(logger).to have_received(:debug).with('[TokenProvider] Test message')
    end

    it 'does not log when no logger provided' do
      expect {
        token_provider.send(:log_debug, 'Test message')
      }.not_to raise_error
    end
  end
end

# Test TokenResponse separately
RSpec.describe Eryph::ClientRuntime::TokenResponse do
  let(:token_response) do
    described_class.new(
      access_token: 'test_token',
      token_type: 'Bearer',
      expires_in: 3600,
      scopes: ['read', 'write']
    )
  end

  describe '#initialize' do
    it 'sets all attributes' do
      expect(token_response.access_token).to eq('test_token')
      expect(token_response.token_type).to eq('Bearer')
      expect(token_response.expires_in).to eq(3600)
      expect(token_response.scopes).to eq(['read', 'write'])
      expect(token_response.issued_at).to be_within(1).of(Time.now)
    end

    it 'uses default token type when not provided' do
      response = described_class.new(access_token: 'token', expires_in: 3600)

      expect(response.token_type).to eq('Bearer')
    end

    it 'converts expires_in to integer' do
      response = described_class.new(access_token: 'token', expires_in: '3600')

      expect(response.expires_in).to eq(3600)
      expect(response.expires_in).to be_a(Integer)
    end

    it 'uses empty array for scopes when not provided' do
      response = described_class.new(access_token: 'token', expires_in: 3600)

      expect(response.scopes).to eq([])
    end
  end

  describe '#expired?' do
    it 'returns false for non-expired token' do
      expect(token_response.expired?).to be false
    end

    it 'returns true for expired token' do
      expired_response = described_class.new(
        access_token: 'token',
        expires_in: -1  # Already expired
      )

      expect(expired_response.expired?).to be true
    end

    it 'returns true when expires_in is zero or negative' do
      zero_response = described_class.new(access_token: 'token', expires_in: 0)

      expect(zero_response.expired?).to be true
    end

    it 'uses buffer time for expiration check' do
      # Token expires in 200 seconds, but with 300 second buffer it's considered expired
      soon_expired = described_class.new(
        access_token: 'token',
        expires_in: 200
      )

      expect(soon_expired.expired?(300)).to be true
      expect(soon_expired.expired?(100)).to be false
    end

    it 'handles time drift correctly' do
      past_time = Time.now - 3700  # 1 hour and 10 minutes ago
      allow(Time).to receive(:now).and_return(past_time, Time.now)

      # Token was issued 1 hour 10 minutes ago, expires in 1 hour, so should be expired
      old_response = described_class.new(
        access_token: 'token',
        expires_in: 3600
      )

      expect(old_response.expired?).to be true
    end
  end

  describe '#authorization_header' do
    it 'returns correctly formatted authorization header' do
      expect(token_response.authorization_header).to eq('Bearer test_token')
    end

    it 'works with custom token type' do
      custom_response = described_class.new(
        access_token: 'custom_token',
        token_type: 'Custom',
        expires_in: 3600
      )

      expect(custom_response.authorization_header).to eq('Custom custom_token')
    end
  end
end