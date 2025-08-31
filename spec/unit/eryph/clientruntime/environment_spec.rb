require 'spec_helper'

RSpec.describe Eryph::ClientRuntime::Environment do
  subject { described_class.new }

  describe '#windows?' do
    it 'returns true on Windows' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_os').and_return('mswin32')
      expect(subject.windows?).to be true
    end

    it 'returns true on MinGW' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_os').and_return('mingw32')
      expect(subject.windows?).to be true
    end

    it 'returns false on Linux' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_os').and_return('linux-gnu')
      expect(subject.windows?).to be false
    end

    it 'returns false on macOS' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_os').and_return('darwin20.0')
      expect(subject.windows?).to be false
    end
  end

  describe '#macos?' do
    it 'returns true on macOS' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_os').and_return('darwin20.0')
      expect(subject.macos?).to be_truthy
    end

    it 'returns false on Linux' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_os').and_return('linux-gnu')
      expect(subject.macos?).to be_falsy
    end

    it 'returns false on Windows' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_os').and_return('mswin32')
      expect(subject.macos?).to be_falsy
    end
  end

  describe '#linux?' do
    it 'returns true on Linux' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_os').and_return('linux-gnu')
      expect(subject.linux?).to be_truthy
    end

    it 'returns false on Windows' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_os').and_return('mswin32')
      expect(subject.linux?).to be_falsy
    end

    it 'returns false on macOS' do
      allow(RbConfig::CONFIG).to receive(:[]).with('target_os').and_return('darwin20.0')
      expect(subject.linux?).to be_falsy
    end
  end

  describe '#execute_powershell_script_file', :skip => !RbConfig::CONFIG['target_os'].match(/mswin|mingw|cygwin/) do
    it 'executes command and parses output' do
      script_file = nil
      begin
        # Create a temporary PowerShell script that should succeed
        script_file = subject.create_temp_file('test_script', '.ps1')
        script_file.write('Write-Output "test success"')
        script_file.close

        result = subject.execute_powershell_script_file(script_file.path)

        expect(result).to be true
      ensure
        script_file&.close
        File.unlink(script_file.path) if script_file && File.exist?(script_file.path)
      end
    end

    it 'executes command with error and receives error' do
      script_file = nil
      begin
        # Create a temporary PowerShell script that should fail silently
        script_file = subject.create_temp_file('error_script', '.ps1')
        script_file.write('exit 1')
        script_file.close

        result = subject.execute_powershell_script_file(script_file.path)

        expect(result).to be false
      ensure
        script_file&.close
        File.unlink(script_file.path) if script_file && File.exist?(script_file.path)
      end
    end
  end
end