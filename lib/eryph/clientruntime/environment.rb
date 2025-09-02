require 'rbconfig'
require 'json'
require 'uri'

module Eryph
  module ClientRuntime
    # Cross-platform environment abstraction
    # Provides platform-specific file system access and configuration paths
    class Environment
      # Configuration store locations
      module ConfigStoreLocation
        CURRENT_DIRECTORY = :current_directory
        USER = :user
        SYSTEM = :system
      end

      # Get the configuration path for the specified location
      # @param location [Symbol] the configuration store location
      # @return [String] the configuration path
      def get_config_path(location)
        case location
        when ConfigStoreLocation::CURRENT_DIRECTORY
          Dir.pwd
        when ConfigStoreLocation::USER
          user_config_path
        when ConfigStoreLocation::SYSTEM
          system_config_path
        else
          raise ArgumentError, "Unknown configuration store location: #{location}"
        end
      end

      # Check if running on Windows platform
      # @return [Boolean] true if running on Windows
      def windows?
        !!(RbConfig::CONFIG['target_os'] =~ /mswin|mingw|cygwin/)
      end

      # Check if running on macOS platform
      # @return [Boolean] true if running on macOS
      def macos?
        RbConfig::CONFIG['target_os'] =~ /darwin/
      end

      # Check if running on Linux platform
      # @return [Boolean] true if running on Linux
      def linux?
        RbConfig::CONFIG['target_os'] =~ /linux/
      end

      # Get the current directory
      # @return [String] current working directory
      def current_directory
        Dir.pwd
      end

      # Check if a file exists
      # @param path [String] file path
      # @return [Boolean] true if file exists
      def file_exists?(path)
        File.exist?(path) && File.file?(path)
      end

      # Check if a directory exists
      # @param path [String] directory path
      # @return [Boolean] true if directory exists
      def directory_exists?(path)
        File.exist?(path) && File.directory?(path)
      end

      # Read file content
      # @param path [String] file path
      # @return [String] file content
      # @raise [IOError] if file cannot be read
      def read_file(path)
        File.read(path)
      rescue Errno::ENOENT, Errno::EACCES => e
        raise IOError, "Cannot read file #{path}: #{e.message}"
      end

      # Write file content
      # @param path [String] file path
      # @param content [String] content to write
      # @raise [IOError] if file cannot be written
      def write_file(path, content)
        # Ensure directory exists
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless directory_exists?(dir)

        File.write(path, content)
      rescue Errno::EACCES, Errno::ENOENT => e
        raise IOError, "Cannot write file #{path}: #{e.message}"
      end

      # Create directory if it doesn't exist
      # @param path [String] directory path
      # @raise [IOError] if directory cannot be created
      def ensure_directory(path)
        return if directory_exists?(path)

        FileUtils.mkdir_p(path)
      rescue Errno::EACCES => e
        raise IOError, "Cannot create directory #{path}: #{e.message}"
      end

      # Check if current user has admin/root privileges
      # @return [Boolean] true if user has elevated privileges
      def admin_user?
        if windows?
          # Check if running as administrator on Windows using PowerShell
          check_windows_admin_privileges
        else
          # Check if running as root on Unix-like systems
          Process.uid.zero?
        end
      end

      # Get environment variable with optional default
      # @param name [String] environment variable name
      # @param default [String, nil] default value if not found
      # @return [String, nil] environment variable value
      def get_environment_variable(name, default = nil)
        ENV[name] || default
      end

      # Create a temporary file
      # @param prefix [String] filename prefix
      # @param suffix [String] filename suffix
      # @return [Tempfile] temporary file object
      def create_temp_file(prefix, suffix = '')
        require 'tempfile'
        Tempfile.new([prefix, suffix])
      end

      # Execute PowerShell script from file
      # @param script_path [String] path to PowerShell script file
      # @return [Boolean] true if script executed successfully
      def execute_powershell_script_file(script_path)
        return false unless windows?

        # Try regular PowerShell first
        success = execute_command('powershell.exe', '-ExecutionPolicy', 'Bypass', '-NoProfile', '-File', script_path)

        # If that fails, try the full path
        success ||= execute_command(
          'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
          '-ExecutionPolicy', 'Bypass', '-NoProfile', '-File', script_path
        )

        success
      end

      # Get application data path (system-wide)
      # @param app_name [String] application name (default: 'eryph')
      # @return [String] application data path
      def get_application_data_path(app_name = 'eryph')
        if windows?
          # Windows: Use PROGRAMDATA
          program_data = get_environment_variable('PROGRAMDATA', 'C:/ProgramData')
          File.join(program_data, app_name)
        else
          # Unix-like: Use /var/lib for system data
          File.join('/var/lib', app_name)
        end
      end

      # Check if a process is running
      # @param process_id [Integer] process ID
      # @param process_name [String, nil] optional process name for verification
      # @return [Boolean] true if process is running
      def process_running?(process_id, process_name = nil)
        return false if process_id.nil? || process_id <= 0

        if windows?
          # On Windows, use PowerShell to check if process exists
          execute_command('powershell', '-Command',
                          "Get-Process -Id #{process_id} -ErrorAction SilentlyContinue | Out-Null")
        elsif file_exists?("/proc/#{process_id}")
          # On Unix-like systems, check /proc or use ps
          return true unless process_name

          # Verify process name if provided
          begin
            cmdline = read_file("/proc/#{process_id}/cmdline")
            cmdline.include?(process_name)
          rescue IOError
            false
          end
        else
          # Fallback to ps command
          execute_command('ps', '-p', process_id.to_s)
        end
      rescue StandardError
        false
      end

      # Get encrypted system client private key for identity provider
      # @param identity_provider_name [String] identity provider name ('zero' or 'local')
      # @param identity_endpoint [String] identity endpoint for DPAPI entropy
      # @return [String, nil] private key PEM content or nil if not found
      def get_encrypted_system_client(identity_provider_name, identity_endpoint = nil)
        private_key_path = File.join(
          get_application_data_path,
          identity_provider_name,
          'private',
          'clients',
          'system-client.key'
        )

        return nil unless file_exists?(private_key_path)

        encrypted_data = read_binary_file(private_key_path)

        if windows?
          # On Windows, decrypt DPAPI-protected data
          decrypted_data = decrypt_dpapi_data(encrypted_data, identity_endpoint)
          raise IOError, 'Failed to decrypt system client private key using DPAPI' if decrypted_data.nil?

          decrypted_data
        else
          # On non-Windows systems, assume it's already in PEM format
          encrypted_data
        end
      end

      # Decrypt DPAPI-protected data (Windows only)
      # @param encrypted_data [String] binary encrypted data
      # @param entropy [String, nil] entropy string (typically the identity endpoint URI)
      # @return [String, nil] decrypted PEM private key or nil if decryption fails
      def decrypt_dpapi_data(encrypted_data, entropy = nil)
        return nil unless windows?

        # Create cache key from encrypted data and entropy
        require 'digest'
        cache_key = Digest::SHA256.hexdigest("#{encrypted_data}#{entropy}")

        # Check cache first
        return @dpapi_cache[cache_key] if @dpapi_cache && @dpapi_cache[cache_key]

        temp_file = nil
        script_file = nil
        output_file = nil

        begin
          # Create temporary files for DPAPI decryption process
          temp_file = create_temp_file('encrypted_key', '.bin')
          temp_file.binmode
          temp_file.write(encrypted_data)
          temp_file.close

          script_file = create_temp_file('decrypt_dpapi', '.ps1')
          output_file = create_temp_file('decrypted_output', '.txt')

          # Close output file immediately after creation so PowerShell can write to it
          output_file.close

          # Create PowerShell script for DPAPI decryption
          entropy_value = entropy&.gsub("'", "''")
          script_content = create_dpapi_decrypt_script(
            temp_file.path.gsub('/', '\\'),
            output_file.path.gsub('/', '\\'),
            entropy_value
          )

          # Write script content and close file properly
          script_file.write(script_content)
          script_file.close

          # Execute PowerShell script
          script_path = script_file.path.gsub('/', '\\')

          success = execute_powershell_script_file(script_path)

          result = nil
          if success && file_exists?(output_file.path) && File.size(output_file.path).positive?
            output_content = read_file(output_file.path).strip
            # Return the result if it doesn't contain an error
            result = output_content.start_with?('ERROR:') ? nil : output_content
          end

          # Cache the result (including nil results to avoid repeated failures)
          @dpapi_cache ||= {}
          @dpapi_cache[cache_key] = result

          result
        ensure
          temp_file&.close
          script_file&.close
          output_file&.close
          File.unlink(temp_file.path) if temp_file && File.exist?(temp_file.path)
          File.unlink(script_file.path) if script_file && File.exist?(script_file.path)
          File.unlink(output_file.path) if output_file && File.exist?(output_file.path)
        end
      end

      private

      # Check if running as administrator on Windows using PowerShell
      # @return [Boolean] true if current process has admin privileges
      def check_windows_admin_privileges
        # Use PowerShell to check if current user is in Administrators group and process is elevated
        cmd = '([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent())' \
              '.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)'
        result = `powershell.exe -Command "#{cmd}" 2>nul`.strip
        result.downcase == 'true'
      rescue StandardError
        # If PowerShell fails for any reason, assume not admin
        false
      end

      # Read binary file content
      # @param path [String] file path
      # @return [String] binary file content
      # @raise [IOError] if file cannot be read
      def read_binary_file(path)
        File.binread(path)
      rescue Errno::ENOENT, Errno::EACCES => e
        raise IOError, "Cannot read binary file #{path}: #{e.message}"
      end

      # Execute a system command
      # @param command [String] command to execute
      # @param args [Array<String>] command arguments
      # @return [Boolean] true if command succeeded
      def execute_command(command, *args)
        if args.empty?
          system(command)
        else
          system(command, *args)
        end
      end

      # Execute PowerShell script and return output
      # @param script_content [String] PowerShell script content
      # @return [String, nil] script output or nil if failed
      def execute_powershell_script(script_content)
        return nil unless windows?

        require 'tempfile'
        script_file = nil
        output_file = nil

        begin
          script_file = create_temp_file('powershell_script', '.ps1')
          output_file = create_temp_file('powershell_output', '.txt')

          write_file(script_file.path, script_content)

          # Execute PowerShell script
          script_path = script_file.path.gsub('/', '\\')
          output_path = output_file.path.gsub('/', '\\')

          # Modify script to redirect output to file
          unless script_content.include?('Out-File')
            modified_script = script_content + "\n} | Out-File -FilePath '#{output_path}' -Encoding UTF8"
          end
          write_file(script_file.path, modified_script || script_content)

          success = execute_command('powershell.exe', '-ExecutionPolicy', 'Bypass', '-NoProfile', '-File', script_path)

          if success && file_exists?(output_file.path)
            result = read_file(output_file.path).strip
            result.empty? ? nil : result
          end
        rescue StandardError
          nil
        ensure
          script_file&.close
          output_file&.close
          File.unlink(script_file.path) if script_file && File.exist?(script_file.path)
          File.unlink(output_file.path) if output_file && File.exist?(output_file.path)
        end
      end

      def user_config_path
        if windows?
          # Windows: Use APPDATA
          get_environment_variable('APPDATA') || File.expand_path('~/AppData/Roaming')
        else
          # Unix-like: Use XDG_CONFIG_HOME or fallback to ~/.config
          get_environment_variable('XDG_CONFIG_HOME') || File.expand_path('~/.config')
        end
      end

      def system_config_path
        if windows?
          # Windows: Use PROGRAMDATA
          get_environment_variable('PROGRAMDATA', 'C:/ProgramData')
        else
          # Unix-like: Use /etc
          '/etc'
        end
      end

      def create_dpapi_decrypt_script(encrypted_file_path, output_file_path, entropy_value)
        <<~PS1
          try {
            # Load required .NET assemblies
            Add-Type -AssemblyName System.Security -ErrorAction Stop
          #{'  '}
            $encryptedBytes = [System.IO.File]::ReadAllBytes('#{encrypted_file_path}')
          #{'  '}
            # Prepare entropy values to try
            $entropyValues = @()
          #{'  '}
            # First try the provided entropy (identity endpoint URI)
            #{"$entropyValues += ,[System.Text.Encoding]::UTF8.GetBytes('#{entropy_value}')" if entropy_value}
          #{'  '}
            # Also try some fallback values
            $entropyValues += ,$null
            $entropyValues += ,[System.Text.Encoding]::UTF8.GetBytes("eryph")
            $entropyValues += ,[System.Text.Encoding]::UTF8.GetBytes("zero")
          #{'  '}
            $scopes = @([System.Security.Cryptography.DataProtectionScope]::CurrentUser, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
          #{'  '}
            foreach ($entropy in $entropyValues) {
              foreach ($scope in $scopes) {
                try {
                  $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedBytes, $entropy, $scope)
                  $decryptedString = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
                  [System.IO.File]::WriteAllText('#{output_file_path}', $decryptedString)
                  exit 0
                } catch {
                  # Continue to next combination
                }
              }
            }
          #{'  '}
            # If we get here, all combinations failed
            [System.IO.File]::WriteAllText('#{output_file_path}', "ERROR: All DPAPI decryption attempts failed")
            exit 1
          } catch {
            [System.IO.File]::WriteAllText('#{output_file_path}', "ERROR: $($_.Exception.Message)")
            exit 1
          }
        PS1
      end
    end
  end
end
