require 'English'
require 'integration_helper'
require 'securerandom'

RSpec.describe 'Configuration Store Discovery', :integration do
  let(:test_config_name) { "test-stores-#{SecureRandom.hex(4)}" }

  after do
    # Cleanup test configurations by deleting files directly from %APPDATA%\Roaming\.eryph
    eryph_dir = File.join(ENV.fetch('APPDATA', nil), '.eryph')
    config_file = File.join(eryph_dir, "#{test_config_name}.config")
    FileUtils.rm_f(config_file)

    # Also clean credentials
    Dir.glob(File.join(eryph_dir, "#{test_config_name}-*.credentials")).each do |file|
      File.delete(file)
    end

    # Clean from current directory too
    current_eryph_dir = './.eryph'
    if Dir.exist?(current_eryph_dir)
      config_file = File.join(current_eryph_dir, "#{test_config_name}.config")
      FileUtils.rm_f(config_file)
      Dir.glob(File.join(current_eryph_dir, "#{test_config_name}-*.credentials")).each do |file|
        File.delete(file)
      end
    end
  end

  describe 'store location discovery' do
    %w[CurrentDirectory User System].each do |store_location|
      it "discovers configurations from #{store_location} store" do
        # Create a basic client configuration in that store
        test_client_id = "test-client-#{SecureRandom.hex(4)}"
        temp_key = File.join(Dir.tmpdir, "#{test_client_id}.key")
        File.write(temp_key, OpenSSL::PKey::RSA.generate(2048).to_pem)

        begin
          # PowerShell sets store location and creates configuration in single session
          # CRITICAL: Run PowerShell in same directory as Ruby test
          current_dir = Dir.pwd
          # Create client in specific store
          `powershell -Command "
            cd '#{current_dir}';
            Set-EryphConfigurationStore -All #{store_location};
            Get-Content '#{temp_key}' -Raw | New-EryphClientCredentials -Id '#{test_client_id}' -IdentityEndpoint 'https://test.example.com/identity' -Configuration '#{test_config_name}' | Add-EryphClientConfiguration -Id '#{test_client_id}' -Name 'Test Store Client' -Configuration '#{test_config_name}' -AsDefault;
          "`

          # Verify PowerShell can read from the store it just wrote to
          ps_read_result = `powershell -Command "
            cd '#{current_dir}';
            Set-EryphConfigurationStore -All #{store_location};
            Get-EryphClientConfiguration -Configuration #{test_config_name} | ConvertTo-Json
          "`
          expect($CHILD_STATUS.success?).to be_truthy, "PowerShell failed to read configuration from #{store_location} store"

          ps_config = JSON.parse(ps_read_result)
          ps_config = [ps_config] unless ps_config.is_a?(Array)
          found_client = ps_config.find { |c| c['Id'] == test_client_id }
          expect(found_client).not_to be_nil

          # Test Ruby discovers configuration from same store using lower-level credential lookup
          environment = Eryph::ClientRuntime::Environment.new
          reader = Eryph::ClientRuntime::ConfigStoresReader.new(environment)
          lookup = Eryph::ClientRuntime::ClientCredentialsLookup.new(reader, test_config_name)
          ruby_credentials = lookup.find_credentials
          expect(ruby_credentials.client_id).to eq(test_client_id)
        ensure
          FileUtils.rm_f(temp_key)
        end
      end
    end
  end

  describe 'store precedence' do
    it 'follows CurrentDirectory > User > System precedence' do
      test_client_id = "test-precedence-#{SecureRandom.hex(4)}"
      temp_key = File.join(Dir.tmpdir, "#{test_client_id}.key")
      File.write(temp_key, OpenSSL::PKey::RSA.generate(2048).to_pem)

      begin
        # Create same-named configuration in User store first
        current_dir = Dir.pwd
        # Create client in User store
        `powershell -Command "
          cd '#{current_dir}';
          Set-EryphConfigurationStore -All User;
          $creds = New-EryphClientCredentials -Id '#{test_client_id}-user' -IdentityEndpoint 'https://user.example.com/identity' -Configuration '#{test_config_name}' -InputObject (Get-Content '#{temp_key}' -Raw);
          Add-EryphClientConfiguration -Id '#{test_client_id}-user' -Name 'User Store Client' -Credentials $creds -Configuration '#{test_config_name}' -AsDefault;
        "`

        # Create client in CurrentDirectory store (higher precedence)
        `powershell -Command "
          cd '#{current_dir}';
          Set-EryphConfigurationStore -All CurrentDirectory;
          $creds = New-EryphClientCredentials -Id '#{test_client_id}-current' -IdentityEndpoint 'https://current.example.com/identity' -Configuration '#{test_config_name}' -InputObject (Get-Content '#{temp_key}' -Raw);
          Add-EryphClientConfiguration -Id '#{test_client_id}-current' -Name 'Current Dir Client' -Credentials $creds -Configuration '#{test_config_name}' -AsDefault;
        "`

        # Ruby should find CurrentDirectory version (higher precedence) using lower-level credential lookup
        environment = Eryph::ClientRuntime::Environment.new
        reader = Eryph::ClientRuntime::ConfigStoresReader.new(environment)
        lookup = Eryph::ClientRuntime::ClientCredentialsLookup.new(reader, test_config_name)
        ruby_credentials = lookup.find_credentials

        expect(ruby_credentials.client_id).to eq("#{test_client_id}-current")
        expect(ruby_credentials.token_endpoint).to include('current.example.com')
      ensure
        FileUtils.rm_f(temp_key)
      end
    end
  end
end
