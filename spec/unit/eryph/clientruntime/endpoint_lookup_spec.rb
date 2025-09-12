require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::EndpointLookup do
  # Test with real business logic - Environment is the only mocked boundary
  describe 'real business logic tests' do
    let(:test_environment) { TestEnvironment.new }
    let(:reader) { Eryph::ClientRuntime::ConfigStoresReader.new(test_environment) }

    describe '#initialize' do
      it 'stores reader and config name' do
        lookup = described_class.new(reader, 'test')

        expect(lookup.reader).to eq(reader)
        expect(lookup.config_name).to eq('test')
      end
    end

    describe '#endpoint' do
      context 'with endpoints in configuration store' do
        before do
          config_path = File.join(
            test_environment.get_config_path(:user),
            '.eryph',
            'test.config'
          )

          config_data = {
            'endpoints' => {
              'identity' => 'https://test.eryph.local/identity',
              'compute' => 'https://test.eryph.local/compute',
            },
          }

          test_environment.add_config_file(config_path, config_data)
        end

        it 'returns endpoint URL from configuration store' do
          lookup = described_class.new(reader, 'test')

          identity_endpoint = lookup.endpoint('identity')
          compute_endpoint = lookup.endpoint('compute')

          expect(identity_endpoint).to eq('https://test.eryph.local/identity')
          expect(compute_endpoint).to eq('https://test.eryph.local/compute')
        end

        it 'returns nil for non-existent endpoint' do
          lookup = described_class.new(reader, 'test')

          endpoint = lookup.endpoint('nonexistent')

          expect(endpoint).to be_nil
        end
      end

      context 'with zero configuration (local endpoints)' do
        before do
          # Setup eryph-zero running locally
          test_environment
            .set_windows(true)
            .add_running_process('eryph-zero', pid: 1234)
            .add_zero_metadata(
              identity_endpoint: 'https://localhost:8080/identity',
              compute_endpoint: 'https://localhost:8080/compute'
            )
        end

        it 'discovers endpoints from local eryph-zero instance' do
          lookup = described_class.new(reader, 'zero')

          identity_endpoint = lookup.endpoint('identity')
          compute_endpoint = lookup.endpoint('compute')

          expect(identity_endpoint).to eq('https://localhost:8080/identity')
          expect(compute_endpoint).to eq('https://localhost:8080/compute')
        end

        it 'returns nil when eryph-zero is not running' do
          # Don't set up running process
          test_environment_no_process = TestEnvironment.new.set_windows(true)
          reader_no_process = Eryph::ClientRuntime::ConfigStoresReader.new(test_environment_no_process)
          lookup = described_class.new(reader_no_process, 'zero')

          endpoint = lookup.endpoint('identity')

          expect(endpoint).to be_nil
        end
      end

      context 'with local configuration (local endpoints)' do
        before do
          # Setup eryph-local running
          test_environment
            .set_windows(true)
            .add_running_process('eryph-local', pid: 5678)
            .add_local_metadata(
              identity_endpoint: 'https://localhost:8081/identity',
              compute_endpoint: 'https://localhost:8081/compute'
            )
        end

        it 'discovers endpoints from local eryph instance' do
          lookup = described_class.new(reader, 'local')

          identity_endpoint = lookup.endpoint('identity')
          compute_endpoint = lookup.endpoint('compute')

          expect(identity_endpoint).to eq('https://localhost:8081/identity')
          expect(compute_endpoint).to eq('https://localhost:8081/compute')
        end
      end

      context 'with configuration store and local endpoints' do
        before do
          # Setup both configuration store and local endpoints
          config_path = File.join(
            test_environment.get_config_path(:user),
            '.eryph',
            'zero.config'
          )

          config_data = {
            'endpoints' => {
              'identity' => 'https://override.eryph.local/identity',
            },
          }

          test_environment
            .set_windows(true)
            .add_config_file(config_path, config_data)
            .add_running_process('eryph-zero', pid: 1234)
            .add_zero_metadata(
              identity_endpoint: 'https://localhost:8080/identity',
              compute_endpoint: 'https://localhost:8080/compute'
            )
        end

        it 'prioritizes configuration store over local endpoints' do
          lookup = described_class.new(reader, 'zero')

          # Identity should come from config store (higher priority)
          identity_endpoint = lookup.endpoint('identity')
          # Compute should come from local (not in config store)
          compute_endpoint = lookup.endpoint('compute')

          expect(identity_endpoint).to eq('https://override.eryph.local/identity')
          expect(compute_endpoint).to eq('https://localhost:8080/compute')
        end
      end
    end

    describe '#all_endpoints' do
      it 'returns merged endpoints from store and local sources' do
        # Setup both sources
        config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'zero.config'
        )

        config_data = {
          'endpoints' => {
            'identity' => 'https://config.eryph.local/identity',
            'custom' => 'https://config.eryph.local/custom',
          },
        }

        test_environment
          .set_windows(true)
          .add_config_file(config_path, config_data)
          .add_running_process('eryph-zero', pid: 1234)
          .add_zero_metadata(
            identity_endpoint: 'https://localhost:8080/identity',
            compute_endpoint: 'https://localhost:8080/compute'
          )

        lookup = described_class.new(reader, 'zero')
        all_endpoints = lookup.all_endpoints

        # Config store endpoints should override local ones
        expect(all_endpoints['identity']).to eq('https://config.eryph.local/identity')
        expect(all_endpoints['custom']).to eq('https://config.eryph.local/custom')
        # Local-only endpoint should be present
        expect(all_endpoints['compute']).to eq('https://localhost:8080/compute')
      end

      it 'returns only local endpoints when no config store exists' do
        test_environment
          .set_windows(true)
          .add_running_process('eryph-zero', pid: 1234)
          .add_zero_metadata(
            identity_endpoint: 'https://localhost:8080/identity',
            compute_endpoint: 'https://localhost:8080/compute'
          )

        lookup = described_class.new(reader, 'zero')
        all_endpoints = lookup.all_endpoints

        expect(all_endpoints).to eq({
                                      'identity' => 'https://localhost:8080/identity',
                                      'compute' => 'https://localhost:8080/compute',
                                    })
      end

      it 'returns only config store endpoints when no local endpoints exist' do
        config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'test.config'
        )

        config_data = {
          'endpoints' => {
            'identity' => 'https://test.eryph.local/identity',
            'compute' => 'https://test.eryph.local/compute',
          },
        }

        test_environment.add_config_file(config_path, config_data)

        lookup = described_class.new(reader, 'test')
        all_endpoints = lookup.all_endpoints

        expect(all_endpoints).to eq({
                                      'identity' => 'https://test.eryph.local/identity',
                                      'compute' => 'https://test.eryph.local/compute',
                                    })
      end

      it 'returns empty hash when no endpoints exist anywhere' do
        lookup = described_class.new(reader, 'nonexistent')
        all_endpoints = lookup.all_endpoints

        expect(all_endpoints).to eq({})
      end
    end

    describe '#endpoint_exists?' do
      before do
        config_path = File.join(
          test_environment.get_config_path(:user),
          '.eryph',
          'test.config'
        )

        config_data = {
          'endpoints' => {
            'identity' => 'https://test.eryph.local/identity',
          },
        }

        test_environment.add_config_file(config_path, config_data)
      end

      it 'returns true for existing endpoint' do
        lookup = described_class.new(reader, 'test')

        exists = lookup.endpoint_exists?('identity')

        expect(exists).to be true
      end

      it 'returns false for non-existent endpoint' do
        lookup = described_class.new(reader, 'test')

        exists = lookup.endpoint_exists?('nonexistent')

        expect(exists).to be false
      end
    end

    describe 'nil config_name handling (the bug we fixed)' do
      it 'handles nil config_name without crashing' do
        # This tests the fix for the nil.downcase bug
        lookup = described_class.new(reader, nil)

        # Should not crash with NoMethodError: undefined method `downcase' for nil
        expect do
          lookup.endpoint('identity')
        end.not_to raise_error
      end

      it 'returns nil for all endpoints when config_name is nil' do
        lookup = described_class.new(reader, nil)

        identity_endpoint = lookup.endpoint('identity')
        all_endpoints = lookup.all_endpoints

        expect(identity_endpoint).to be_nil
        expect(all_endpoints).to eq({})
      end
    end
  end

  # Special case tests - mock complex external dependencies
  describe 'local endpoint discovery edge cases' do
    let(:test_environment) { TestEnvironment.new }
    let(:reader) { Eryph::ClientRuntime::ConfigStoresReader.new(test_environment) }

    context 'when LocalIdentityProviderInfo fails' do
      it 'handles provider info errors gracefully' do
        # Setup environment that will cause provider info to fail
        test_environment
          .set_windows(true)
          .add_running_process('eryph-zero', pid: 1234)
        # Don't add metadata file - this will cause provider to fail

        lookup = described_class.new(reader, 'zero')

        # Should not crash, just return nil
        endpoint = lookup.endpoint('identity')

        expect(endpoint).to be_nil
      end
    end
  end
end
