require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::LocalIdentityProviderInfo do
  let(:mock_environment) { double('Environment') }
  subject { described_class.new(mock_environment, 'zero') }

  describe '#initialize' do
    it 'stores environment and provider name' do
      provider = described_class.new(mock_environment, 'test-provider')
      
      expect(provider.environment).to eq(mock_environment)
      expect(provider.identity_provider_name).to eq('test-provider')
    end

    it 'defaults to identity provider name' do
      provider = described_class.new(mock_environment)
      
      expect(provider.identity_provider_name).to eq('identity')
    end
  end

  describe '#running?' do
    let(:lock_file_path) { 'C:/ProgramData/eryph/zero/.lock' }
    let(:metadata) { { 'processName' => 'eryph-zero', 'processId' => 1234 } }

    before do
      allow(mock_environment).to receive(:get_application_data_path).and_return('C:/ProgramData/eryph')
      allow(mock_environment).to receive(:file_exists?).with(lock_file_path).and_return(true)
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return(JSON.generate(metadata))
    end

    it 'returns true when provider is running' do
      allow(mock_environment).to receive(:process_running?).with(1234, 'eryph-zero').and_return(true)
      
      result = subject.running?
      
      expect(result).to be true
    end

    it 'returns false when metadata is empty' do
      allow(mock_environment).to receive(:file_exists?).with(lock_file_path).and_return(false)
      
      result = subject.running?
      
      expect(result).to be false
    end

    it 'returns false when process is not running' do
      allow(mock_environment).to receive(:process_running?).with(1234, 'eryph-zero').and_return(false)
      
      result = subject.running?
      
      expect(result).to be false
    end

    it 'returns false when process name is nil' do
      invalid_metadata = { 'processId' => 1234 }
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return(JSON.generate(invalid_metadata))
      
      result = subject.running?
      
      expect(result).to be false
    end

    it 'returns false when process name is empty' do
      invalid_metadata = { 'processName' => '', 'processId' => 1234 }
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return(JSON.generate(invalid_metadata))
      
      result = subject.running?
      
      expect(result).to be false
    end

    it 'returns false when process ID is nil' do
      invalid_metadata = { 'processName' => 'eryph-zero' }
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return(JSON.generate(invalid_metadata))
      
      result = subject.running?
      
      expect(result).to be false
    end

    it 'handles JSON parse errors gracefully' do
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return('invalid json')
      
      result = subject.running?
      
      expect(result).to be false
    end

    it 'handles IO errors gracefully' do
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_raise(IOError.new('Read failed'))
      
      result = subject.running?
      
      expect(result).to be false
    end

    it 'strips BOM from file content' do
      content_with_bom = "\xEF\xBB\xBF" + JSON.generate(metadata)
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return(content_with_bom)
      allow(mock_environment).to receive(:process_running?).with(1234, 'eryph-zero').and_return(true)
      
      result = subject.running?
      
      expect(result).to be true
    end
  end

  describe '#endpoints' do
    let(:lock_file_path) { 'C:/ProgramData/eryph/zero/.lock' }
    let(:metadata) do
      {
        'processName' => 'eryph-zero',
        'processId' => 1234,
        'endpoints' => {
          'identity' => 'https://localhost:8080/identity',
          'compute' => 'https://localhost:8080/compute',
          'invalid_url' => 'not-a-url',
          'ftp_url' => 'ftp://localhost/files'
        }
      }
    end

    before do
      allow(mock_environment).to receive(:get_application_data_path).and_return('C:/ProgramData/eryph')
      allow(mock_environment).to receive(:file_exists?).with(lock_file_path).and_return(true)
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return(JSON.generate(metadata))
      allow(mock_environment).to receive(:process_running?).with(1234, 'eryph-zero').and_return(true)
    end

    it 'returns valid HTTP/HTTPS endpoints' do
      result = subject.endpoints

      expect(result).to include(
        'identity' => URI.parse('https://localhost:8080/identity'),
        'compute' => URI.parse('https://localhost:8080/compute')
      )
    end

    it 'excludes invalid URLs' do
      result = subject.endpoints

      expect(result).not_to have_key('invalid_url')
    end

    it 'excludes non-HTTP/HTTPS URLs' do
      result = subject.endpoints

      expect(result).not_to have_key('ftp_url')
    end

    it 'returns empty hash when provider not running' do
      allow(mock_environment).to receive(:process_running?).with(1234, 'eryph-zero').and_return(false)

      result = subject.endpoints

      expect(result).to eq({})
    end

    it 'returns empty hash when no endpoints in metadata' do
      metadata_without_endpoints = { 'processName' => 'eryph-zero', 'processId' => 1234 }
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return(JSON.generate(metadata_without_endpoints))

      result = subject.endpoints

      expect(result).to eq({})
    end

    it 'handles URI parse errors gracefully' do
      metadata_with_bad_url = {
        'processName' => 'eryph-zero',
        'processId' => 1234,
        'endpoints' => {
          'identity' => 'https://localhost:8080',
          'bad' => 'ht!tp://bad-url'
        }
      }
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return(JSON.generate(metadata_with_bad_url))

      result = subject.endpoints

      expect(result).to include('identity' => URI.parse('https://localhost:8080'))
      expect(result).not_to have_key('bad')
    end
  end

  describe '#system_client_private_key' do
    let(:endpoints) { { 'identity' => URI.parse('https://localhost:8080/identity') } }
    let(:private_key_content) { 'private-key-content' }

    before do
      allow(subject).to receive(:endpoints).and_return(endpoints)
    end

    it 'returns private key when identity endpoint exists' do
      allow(mock_environment).to receive(:get_encrypted_system_client)
        .with('zero', 'https://localhost:8080/identity')
        .and_return(private_key_content)

      result = subject.system_client_private_key

      expect(result).to eq(private_key_content)
    end

    it 'returns nil when no identity endpoint' do
      allow(subject).to receive(:endpoints).and_return({})

      result = subject.system_client_private_key

      expect(result).to be_nil
    end

    it 'returns nil when environment cannot retrieve key' do
      allow(mock_environment).to receive(:get_encrypted_system_client)
        .with('zero', 'https://localhost:8080/identity')
        .and_return(nil)

      result = subject.system_client_private_key

      expect(result).to be_nil
    end
  end

  describe '#system_client_credentials' do
    let(:endpoints) { { 'identity' => URI.parse('https://localhost:8080/identity') } }
    let(:private_key_content) { 'private-key-content' }

    before do
      allow(subject).to receive(:endpoints).and_return(endpoints)
    end

    context 'when private key is available' do
      before do
        allow(subject).to receive(:system_client_private_key).and_return(private_key_content)
      end

      it 'returns credentials hash' do
        result = subject.system_client_credentials

        expect(result).to eq({
          'id' => 'system-client',
          'name' => 'Eryph Zero System Client',
          'private_key' => private_key_content,
          'identity_endpoint' => 'https://localhost:8080/identity'
        })
      end
    end

    context 'when no identity endpoint' do
      it 'returns nil' do
        allow(subject).to receive(:endpoints).and_return({})

        result = subject.system_client_credentials

        expect(result).to be_nil
      end
    end

    context 'when private key is not available' do
      it 'returns nil' do
        allow(subject).to receive(:system_client_private_key).and_return(nil)

        result = subject.system_client_credentials

        expect(result).to be_nil
      end
    end
  end

  describe '#get_metadata (private)' do
    let(:lock_file_path) { 'C:/ProgramData/eryph/zero/.lock' }
    let(:metadata) { { 'processName' => 'eryph-zero', 'processId' => 1234 } }

    before do
      allow(mock_environment).to receive(:get_application_data_path).and_return('C:/ProgramData/eryph')
    end

    it 'reads and parses metadata from lock file' do
      allow(mock_environment).to receive(:file_exists?).with(lock_file_path).and_return(true)
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return(JSON.generate(metadata))

      result = subject.send(:get_metadata)

      expect(result).to eq(metadata)
    end

    it 'returns empty hash when lock file does not exist' do
      allow(mock_environment).to receive(:file_exists?).with(lock_file_path).and_return(false)

      result = subject.send(:get_metadata)

      expect(result).to eq({})
    end

    it 'returns empty hash on JSON parse error' do
      allow(mock_environment).to receive(:file_exists?).with(lock_file_path).and_return(true)
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_return('invalid json')

      result = subject.send(:get_metadata)

      expect(result).to eq({})
    end

    it 'returns empty hash on IO error' do
      allow(mock_environment).to receive(:file_exists?).with(lock_file_path).and_return(true)
      allow(mock_environment).to receive(:read_file).with(lock_file_path)
        .and_raise(IOError.new('Read failed'))

      result = subject.send(:get_metadata)

      expect(result).to eq({})
    end

    it 'constructs correct lock file path' do
      expected_path = File.join('C:/ProgramData/eryph', 'zero', '.lock')
      
      expect(mock_environment).to receive(:file_exists?).with(expected_path).and_return(false)

      subject.send(:get_metadata)
    end

    it 'handles different provider names' do
      custom_provider = described_class.new(mock_environment, 'custom-provider')
      expected_path = File.join('C:/ProgramData/eryph', 'custom-provider', '.lock')
      
      expect(mock_environment).to receive(:file_exists?).with(expected_path).and_return(false)

      custom_provider.send(:get_metadata)
    end
  end
end