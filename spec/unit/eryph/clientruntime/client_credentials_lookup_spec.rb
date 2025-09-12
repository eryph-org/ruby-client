require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::ClientCredentialsLookup do
  # Test with real business logic - Environment is the only mocked boundary
  describe 'real business logic tests' do
    let(:test_environment) { TestEnvironment.new }
    let(:reader) { Eryph::ClientRuntime::ConfigStoresReader.new(test_environment) }

    describe 'zero/local config system client fallback' do
      context 'with zero config and no default client' do
        it 'falls back to system client when no default exists' do
          # Setup: no user config but system client available
          test_environment
            .set_windows(true)
            .set_admin(true)
            .add_running_process('eryph-zero', pid: 1234)
            .add_zero_metadata(identity_endpoint: 'https://localhost:8080/identity')
            .add_system_client_files(
              'zero',
              private_key: build(:rsa_private_key).to_pem,
              identity_endpoint: 'https://localhost:8080/identity'
            )

          lookup = described_class.new(reader, 'zero')

          # This should find system client as fallback
          credentials = lookup.find_credentials

          expect(credentials.client_id).to eq('system-client')
          expect(credentials.configuration).to eq('zero')
        end
      end

      context 'with local config and no default client on Windows' do
        it 'falls back to system client when no default exists' do
          # Setup: no user config but system client available on Windows
          test_environment
            .set_windows(true)
            .set_admin(true)
            .add_running_process('eryph-local', pid: 5678)
            .add_local_metadata(identity_endpoint: 'https://localhost:8080/identity')
            .add_system_client_files(
              'local',
              private_key: build(:rsa_private_key).to_pem,
              identity_endpoint: 'https://localhost:8080/identity'
            )

          lookup = described_class.new(reader, 'local')

          # This should find system client as fallback
          credentials = lookup.find_credentials

          expect(credentials.client_id).to eq('system-client')
          expect(credentials.configuration).to eq('local')
        end
      end

      context 'with local config and no default client on Linux' do
        it 'falls back to system client when no default exists' do
          # Setup: no user config but system client available on Linux
          test_environment
            .set_windows(false)
            .set_admin(true)
            .add_running_process('eryph-local', pid: 5678)
            .add_local_metadata(identity_endpoint: 'https://localhost:8080/identity')
            .add_system_client_files(
              'local',
              private_key: build(:rsa_private_key).to_pem,
              identity_endpoint: 'https://localhost:8080/identity'
            )

          lookup = described_class.new(reader, 'local')

          # This should find system client as fallback (key stored directly as PEM)
          credentials = lookup.find_credentials

          expect(credentials.client_id).to eq('system-client')
          expect(credentials.configuration).to eq('local')
        end
      end

      context 'with regular config' do
        it 'does not try system client fallback' do
          # Setup: no user config, no system client for regular config
          test_environment.set_admin(true)

          lookup = described_class.new(reader, 'default')

          # Should raise error, not try system client
          expect do
            lookup.find_credentials
          end.to raise_error(
            Eryph::ClientRuntime::CredentialsNotFoundError,
            "No default client found in configuration 'default'"
          )
        end
      end
    end

    describe 'automatic discovery priority' do
      it 'tries configs in correct order on Windows' do
        test_environment.set_windows(true)

        # Setup default config with client and endpoints
        test_environment.add_client_with_key(
          'default',
          'default-client-id',
          'Default Client',
          endpoints: {
            'identity' => 'https://test.eryph.local/identity',
            'compute' => 'https://test.eryph.local/compute',
          }
        )

        lookup = described_class.new(reader) # No specific config = auto discovery
        credentials = lookup.find_credentials

        # Should find default first
        expect(credentials.client_id).to eq('default-client-id')
        expect(credentials.configuration).to eq('default')
      end

      it 'tries configs in correct order on Linux' do
        test_environment.set_windows(false)

        # Setup local config with client and endpoints
        test_environment.add_client_with_key(
          'local',
          'local-client-id',
          'Local Client',
          endpoints: {
            'identity' => 'https://test.eryph.local/identity',
            'compute' => 'https://test.eryph.local/compute',
          }
        )

        lookup = described_class.new(reader) # No specific config = auto discovery
        credentials = lookup.find_credentials

        # Should find local (skipping zero on Linux)
        expect(credentials.client_id).to eq('local-client-id')
        expect(credentials.configuration).to eq('local')
      end
    end

    describe 'client search methods' do
      before do
        # Setup test config with multiple clients and endpoints
        endpoints = {
          'identity' => 'https://test.eryph.local/identity',
          'compute' => 'https://test.eryph.local/compute',
        }

        test_environment.add_client_with_key(
          'test',
          'client-1',
          'First Client',
          endpoints: endpoints
        )
        test_environment.add_client_with_key(
          'test',
          'client-2',
          'Second Client',
          endpoints: endpoints
        )
      end

      it 'finds credentials by client ID' do
        lookup = described_class.new(reader)
        credentials = lookup.get_credentials_by_client_id('client-1', 'test')

        expect(credentials.client_id).to eq('client-1')
        expect(credentials.client_name).to eq('First Client')
      end

      it 'finds credentials by client name' do
        lookup = described_class.new(reader)
        credentials = lookup.get_credentials_by_client_name('Second Client', 'test')

        expect(credentials.client_id).to eq('client-2')
        expect(credentials.client_name).to eq('Second Client')
      end

      it 'returns nil for non-existent client ID' do
        lookup = described_class.new(reader)
        credentials = lookup.get_credentials_by_client_id('missing', 'test')

        expect(credentials).to be_nil
      end

      it 'returns nil for non-existent client name' do
        lookup = described_class.new(reader)
        credentials = lookup.get_credentials_by_client_name('Missing Client', 'test')

        expect(credentials).to be_nil
      end
    end

    describe 'credentials availability check' do
      it 'returns true when credentials exist' do
        test_environment.add_client_with_key(
          'test',
          'test-client',
          'Test Client',
          endpoints: {
            'identity' => 'https://test.eryph.local/identity',
            'compute' => 'https://test.eryph.local/compute',
          }
        )

        lookup = described_class.new(reader, 'test')

        expect(lookup.credentials_available?).to be true
      end

      it 'returns false when no credentials exist' do
        lookup = described_class.new(reader, 'nonexistent')

        expect(lookup.credentials_available?).to be false
      end
    end
  end

  # Special case tests - mock only the complex external dependencies
  describe 'system client admin privilege validation' do
    let(:mock_environment) { double('Environment') }
    let(:reader) { Eryph::ClientRuntime::ConfigStoresReader.new(mock_environment) }
    let(:lookup) { described_class.new(reader) }

    context 'Windows admin check' do
      before do
        allow(mock_environment).to receive(:windows?).and_return(true)
        allow(mock_environment).to receive(:linux?).and_return(false)
      end

      it 'raises error when not admin on Windows' do
        allow(mock_environment).to receive(:admin_user?).and_return(false)

        expect do
          lookup.send(:get_system_client_credentials, 'zero')
        end.to raise_error(
          Eryph::ClientRuntime::NoUserCredentialsError,
          /requires Administrator privileges/
        )
      end
    end

    context 'Linux root check' do
      before do
        allow(mock_environment).to receive(:windows?).and_return(false)
        allow(mock_environment).to receive(:linux?).and_return(true)
      end

      it 'raises error when not root on Linux' do
        allow(mock_environment).to receive(:admin_user?).and_return(false)

        expect do
          lookup.send(:get_system_client_credentials, 'local')
        end.to raise_error(
          Eryph::ClientRuntime::NoUserCredentialsError,
          /requires root privileges/
        )
      end
    end
  end
end
