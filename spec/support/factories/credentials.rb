FactoryBot.define do
  factory :rsa_private_key, class: 'OpenSSL::PKey::RSA' do
    initialize_with { OpenSSL::PKey::RSA.generate(2048) }
  end
  
  factory :credentials, class: 'Eryph::ClientRuntime::ClientCredentials' do
    client_id { 'test-client-id' }
    client_name { 'Test Client' }
    token_endpoint { 'https://test.eryph.local/identity/connect/token' }
    
    transient do
      # Generate a test RSA key pair
      private_key_content do
        key = OpenSSL::PKey::RSA.generate(2048)
        key.to_pem
      end
    end
    
    private_key { OpenSSL::PKey::RSA.new(private_key_content) }
    
    initialize_with do
      new(
        client_id: client_id,
        client_name: client_name,
        private_key: private_key,
        token_endpoint: token_endpoint
      )
    end
    
    trait :eryph_zero do
      token_endpoint { 'https://localhost:8080/identity/connect/token' }
      client_id { 'system-client' }
      client_name { 'System Client' }
    end
    
    trait :invalid do
      client_id { 'invalid-client-id' }
      client_name { 'Invalid Client' }
    end
  end
  
  factory :token_response, class: 'Eryph::ClientRuntime::TokenResponse' do
    access_token { 'test_access_token_12345' }
    token_type { 'Bearer' }
    expires_in { 3600 }
    scopes { ['compute:read', 'compute:write'] }
    
    initialize_with { new(**attributes) }
    
    trait :expired do
      expires_in { 0 }
    end
    
    trait :short_lived do
      expires_in { 60 }
    end
    
    trait :read_only do
      scopes { ['compute:read'] }
    end
  end
  
  factory :config_data, class: 'Hash' do
    initialize_with do
      {
        'endpoints' => {
          'identity' => 'https://test.eryph.local/identity',
          'compute' => 'https://test.eryph.local/compute'
        },
        'clients' => [
          {
            'id' => 'test-client-id',
            'name' => 'Test Client'
          }
        ],
        'defaultClient' => 'test-client-id'
      }
    end
    
    trait :eryph_zero do
      initialize_with do
        {
          'endpoints' => {
            'identity' => 'https://localhost:8080/identity',
            'compute' => 'https://localhost:8080/compute'
          },
          'clients' => [
            {
              'id' => 'system-client',
              'name' => 'System Client'
            }
          ],
          'defaultClient' => 'system-client'
        }
      end
    end
  end
end