require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::LocalIdentityProviderInfo do
  # Test with real business logic - Environment is the only mocked boundary
  describe 'real business logic tests' do
    let(:test_environment) { TestEnvironment.new }
    let(:identity_provider_name) { 'zero' }
    let(:provider_info) { described_class.new(test_environment, identity_provider_name) }

    describe '#initialize' do
      it 'stores environment and identity provider name' do
        expect(provider_info.environment).to eq(test_environment)
        expect(provider_info.identity_provider_name).to eq('zero')
      end

      it 'defaults identity provider name to identity' do
        default_provider = described_class.new(test_environment)
        expect(default_provider.identity_provider_name).to eq('identity')
      end
    end

    describe '#running?' do
      context 'with valid metadata and running process' do
        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          metadata = {
            'processName' => 'eryph-zero',
            'processId' => 1234,
            'endpoints' => {
              'identity' => 'https://localhost:8080/identity',
              'compute' => 'https://localhost:8080/compute',
            },
          }

          test_environment
            .add_lock_file(lock_file_path, metadata)
            .add_running_process('eryph-zero', pid: 1234)
        end

        it 'returns true when process is running' do
          expect(provider_info.running?).to be true
        end
      end

      context 'with valid metadata but stopped process' do
        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          metadata = {
            'processName' => 'eryph-zero',
            'processId' => 1234,
            'endpoints' => {
              'identity' => 'https://localhost:8080/identity',
            },
          }

          test_environment.add_lock_file(lock_file_path, metadata)
          # Don't add running process - simulates stopped process
        end

        it 'returns false when process is not running' do
          expect(provider_info.running?).to be false
        end
      end

      context 'with invalid metadata' do
        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          # Missing processName or processId
          metadata = {
            'endpoints' => {
              'identity' => 'https://localhost:8080/identity',
            },
          }

          test_environment.add_lock_file(lock_file_path, metadata)
        end

        it 'returns false when processName is missing' do
          expect(provider_info.running?).to be false
        end
      end

      context 'with missing lock file' do
        it 'returns false when no lock file exists' do
          expect(provider_info.running?).to be false
        end
      end

      context 'with malformed JSON in lock file' do
        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          test_environment.add_raw_lock_file(lock_file_path, 'invalid json {')
        end

        it 'returns false for invalid JSON' do
          expect(provider_info.running?).to be false
        end
      end
    end

    describe '#endpoints' do
      context 'with running provider and valid endpoints' do
        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          metadata = {
            'processName' => 'eryph-zero',
            'processId' => 1234,
            'endpoints' => {
              'identity' => 'https://localhost:8080/identity',
              'compute' => 'https://localhost:8080/compute',
              'invalid' => 'not-a-valid-uri',
              'ftp' => 'ftp://localhost:21/ftp', # Not HTTP/HTTPS
            },
          }

          test_environment
            .add_lock_file(lock_file_path, metadata)
            .add_running_process('eryph-zero', pid: 1234)
        end

        it 'returns valid HTTP/HTTPS endpoints as URI objects' do
          endpoints_result = provider_info.endpoints

          expect(endpoints_result).to have_key('identity')
          expect(endpoints_result).to have_key('compute')
          expect(endpoints_result).not_to have_key('invalid')
          expect(endpoints_result).not_to have_key('ftp')

          expect(endpoints_result['identity']).to be_a(URI)
          expect(endpoints_result['identity'].to_s).to eq('https://localhost:8080/identity')
          expect(endpoints_result['compute'].to_s).to eq('https://localhost:8080/compute')
        end
      end

      context 'with stopped provider' do
        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          metadata = {
            'processName' => 'eryph-zero',
            'processId' => 1234,
            'endpoints' => {
              'identity' => 'https://localhost:8080/identity',
            },
          }

          test_environment.add_lock_file(lock_file_path, metadata)
          # Don't add running process
        end

        it 'returns empty hash when provider is not running' do
          endpoints_result = provider_info.endpoints

          expect(endpoints_result).to eq({})
        end
      end

      context 'with missing endpoints in metadata' do
        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          metadata = {
            'processName' => 'eryph-zero',
            'processId' => 1234,
            # No endpoints key
          }

          test_environment
            .add_lock_file(lock_file_path, metadata)
            .add_running_process('eryph-zero', pid: 1234)
        end

        it 'returns empty hash when no endpoints in metadata' do
          endpoints_result = provider_info.endpoints

          expect(endpoints_result).to eq({})
        end
      end
    end

    describe '#system_client_private_key' do
      context 'with running provider and system client' do
        let(:test_key) { 'test-private-key-content' }

        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          metadata = {
            'processName' => 'eryph-zero',
            'processId' => 1234,
            'endpoints' => {
              'identity' => 'https://localhost:8080/identity',
              'compute' => 'https://localhost:8080/compute',
            },
          }

          test_environment
            .add_lock_file(lock_file_path, metadata)
            .add_running_process('eryph-zero', pid: 1234)
            .add_system_client_files('zero', private_key: test_key, identity_endpoint: 'https://localhost:8080/identity')
        end

        it 'returns system client private key' do
          private_key = provider_info.system_client_private_key

          expect(private_key).to eq(test_key)
        end
      end

      context 'without identity endpoint' do
        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          metadata = {
            'processName' => 'eryph-zero',
            'processId' => 1234,
            'endpoints' => {
              'compute' => 'https://localhost:8080/compute',
              # No identity endpoint
            },
          }

          test_environment
            .add_lock_file(lock_file_path, metadata)
            .add_running_process('eryph-zero', pid: 1234)
        end

        it 'returns nil when no identity endpoint' do
          private_key = provider_info.system_client_private_key

          expect(private_key).to be_nil
        end
      end

      context 'when provider is not running' do
        it 'returns nil when provider is not running' do
          private_key = provider_info.system_client_private_key

          expect(private_key).to be_nil
        end
      end
    end

    describe '#system_client_credentials' do
      context 'with running provider and system client' do
        let(:test_key) { 'test-private-key-content' }

        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          metadata = {
            'processName' => 'eryph-zero',
            'processId' => 1234,
            'endpoints' => {
              'identity' => 'https://localhost:8080/identity',
              'compute' => 'https://localhost:8080/compute',
            },
          }

          test_environment
            .add_lock_file(lock_file_path, metadata)
            .add_running_process('eryph-zero', pid: 1234)
            .add_system_client_files('zero', private_key: test_key, identity_endpoint: 'https://localhost:8080/identity')
        end

        it 'returns complete system client credentials hash' do
          credentials = provider_info.system_client_credentials

          expect(credentials).to include(
            'id' => 'system-client',
            'name' => 'Eryph Zero System Client',
            'private_key' => test_key,
            'identity_endpoint' => 'https://localhost:8080/identity'
          )
        end
      end

      context 'without private key' do
        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          metadata = {
            'processName' => 'eryph-zero',
            'processId' => 1234,
            'endpoints' => {
              'identity' => 'https://localhost:8080/identity',
            },
          }

          test_environment
            .add_lock_file(lock_file_path, metadata)
            .add_running_process('eryph-zero', pid: 1234)
          # Don't add system client credentials
        end

        it 'returns nil when no private key available' do
          credentials = provider_info.system_client_credentials

          expect(credentials).to be_nil
        end
      end

      context 'without identity endpoint' do
        before do
          lock_file_path = File.join(
            test_environment.get_application_data_path,
            'zero',
            '.lock'
          )

          metadata = {
            'processName' => 'eryph-zero',
            'processId' => 1234,
            'endpoints' => {
              'compute' => 'https://localhost:8080/compute',
              # No identity endpoint
            },
          }

          test_environment
            .add_lock_file(lock_file_path, metadata)
            .add_running_process('eryph-zero', pid: 1234)
        end

        it 'returns nil when no identity endpoint' do
          credentials = provider_info.system_client_credentials

          expect(credentials).to be_nil
        end
      end
    end
  end

  # Special case tests - mock complex external dependencies
  describe 'edge case error handling' do
    let(:mock_environment) { double('Environment') }
    let(:provider_info) { described_class.new(mock_environment, 'test') }

    context 'when file I/O errors occur' do
      it 'handles file read errors gracefully' do
        lock_file_path = '/test/path/test/.lock'

        allow(mock_environment).to receive(:get_application_data_path).and_return('/test/path')
        allow(mock_environment).to receive(:file_exists?).with(lock_file_path).and_return(true)
        allow(mock_environment).to receive(:read_file).with(lock_file_path).and_raise(IOError, 'Permission denied')

        expect(provider_info.running?).to be false
        expect(provider_info.endpoints).to eq({})
      end
    end

    context 'when JSON parsing fails' do
      it 'handles JSON parser errors gracefully' do
        lock_file_path = '/test/path/test/.lock'

        allow(mock_environment).to receive(:get_application_data_path).and_return('/test/path')
        allow(mock_environment).to receive(:file_exists?).with(lock_file_path).and_return(true)
        allow(mock_environment).to receive(:read_file).with(lock_file_path).and_return('invalid json {')

        expect(provider_info.running?).to be false
        expect(provider_info.endpoints).to eq({})
      end
    end
  end
end
