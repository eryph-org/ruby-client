require 'json'

module Eryph
  module ClientRuntime
    # Provides information about locally running eryph identity providers
    # Mirrors the functionality of LocalIdentityProviderInfo.cs
    class LocalIdentityProviderInfo
      # @return [Environment] environment abstraction
      attr_reader :environment

      # @return [String] identity provider name
      attr_reader :identity_provider_name

      # Initialize local identity provider info
      # @param environment [Environment] environment abstraction
      # @param identity_provider_name [String] identity provider name
      def initialize(environment, identity_provider_name = 'identity')
        @environment = environment
        @identity_provider_name = identity_provider_name
      end

      # Check if the identity provider is running
      # @return [Boolean] true if the identity provider is running
      def running?
        metadata = get_metadata
        return false if metadata.empty?

        process_name = metadata['processName']
        process_id = metadata['processId']

        return false if process_name.nil? || process_name.empty? || process_id.nil?

        # Check if the process is actually running
        is_process_running(process_name, process_id.to_i)
      end

      # Get endpoints from the running identity provider
      # @return [Hash] endpoint name -> URI mapping
      def endpoints
        return {} unless running?

        metadata = get_metadata
        endpoints_data = metadata['endpoints']
        return {} unless endpoints_data

        result = {}
        endpoints_data.each do |key, value|
          begin
            result[key] = URI.parse(value.to_s)
          rescue URI::InvalidURIError
            # Skip invalid URIs
            next
          end
        end

        result
      end

      # Get the system client private key for eryph-zero
      # @return [String, nil] private key content or nil if not found
      def system_client_private_key
        application_data_path = get_application_data_path
        private_key_path = File.join(
          application_data_path,
          @identity_provider_name,
          'private',
          'clients',
          'system-client.key'
        )

        endpoints_hash = endpoints
        return nil unless endpoints_hash.key?('identity')

        # Try to read the private key file
        begin
          if @environment.file_exists?(private_key_path)
            encrypted_data = File.binread(private_key_path)
            
            # On Windows, the private key is encrypted with DPAPI
            # Use PowerShell to decrypt it with identity endpoint as entropy
            if @environment.windows?
              identity_endpoint = endpoints_hash['identity']&.to_s
              decrypt_dpapi_data(encrypted_data, identity_endpoint)
            else
              # On non-Windows systems, assume it's already in PEM format
              encrypted_data
            end
          else
            nil
          end
        rescue IOError
          nil
        end
      end

      # Get system client credentials for eryph-zero
      # @return [Hash, nil] client credentials hash or nil if not available
      def system_client_credentials
        endpoints_hash = endpoints
        return nil unless endpoints_hash.key?('identity')

        private_key = system_client_private_key
        return nil unless private_key

        {
          'id' => 'system-client',
          'name' => 'Eryph Zero System Client',
          'private_key' => private_key,
          'identity_endpoint' => endpoints_hash['identity'].to_s
        }
      end

      private

      def get_metadata
        lock_file_path = get_lock_file_path
        return {} unless @environment.file_exists?(lock_file_path)

        begin
          content = @environment.read_file(lock_file_path)
          # Strip BOM if present
          content = content.sub(/\A\xEF\xBB\xBF/, '')
          JSON.parse(content)
        rescue JSON::ParserError, IOError
          {}
        end
      end

      def get_lock_file_path
        application_data_path = get_application_data_path
        File.join(application_data_path, @identity_provider_name, '.lock')
      end

      def get_application_data_path
        if @environment.windows?
          # Windows: Use PROGRAMDATA
          ENV['PROGRAMDATA'] || 'C:/ProgramData'
        else
          # Unix-like: Use /var/lib for system data
          '/var/lib'
        end.tap do |path|
          return File.join(path, 'eryph')
        end
      end

      def is_process_running(process_name, process_id)
        # Check if the process is still running
        begin
          if @environment.windows?
            # On Windows, use PowerShell to check if process exists
            system("powershell -Command \"Get-Process -Id #{process_id} -ErrorAction SilentlyContinue\" >nul 2>&1")
          else
            # On Unix-like systems, check /proc or use ps
            if File.exist?("/proc/#{process_id}")
              # Check if the process name matches (basic verification)
              begin
                cmdline = File.read("/proc/#{process_id}/cmdline")
                cmdline.include?(process_name)
              rescue
                false
              end
            else
              # Fallback to ps command
              system("ps -p #{process_id} > /dev/null 2>&1")
            end
          end
        rescue
          false
        end
      end

      # Decrypt DPAPI-protected data using PowerShell
      # @param encrypted_data [String] binary encrypted data
      # @param entropy [String, nil] entropy string (typically the identity endpoint URI)
      # @return [String, nil] decrypted PEM private key or nil if decryption fails
      def decrypt_dpapi_data(encrypted_data, entropy = nil)
        return nil unless @environment.windows?

        # Create temporary files
        require 'tempfile'
        
        temp_file = Tempfile.new(['encrypted_key', '.bin'])
        temp_file.binmode
        temp_file.write(encrypted_data)
        temp_file.close

        script_file = Tempfile.new(['decrypt_dpapi', '.ps1'])
        output_file = Tempfile.new(['decrypted_output', '.txt'])
        output_file.close
        
        begin
          # Write PowerShell script that uses the identity endpoint as entropy
          entropy_value = entropy ? entropy.gsub("'", "''") : nil
          script_content = <<~PS1
            try {
              # Load required .NET assemblies
              Add-Type -AssemblyName System.Security -ErrorAction Stop
              
              $encryptedBytes = [System.IO.File]::ReadAllBytes('#{temp_file.path.gsub('/', '\\')}')
              
              # Prepare entropy values to try
              $entropyValues = @()
              
              # First try the provided entropy (identity endpoint URI)
              #{entropy_value ? "$entropyValues += ,[System.Text.Encoding]::UTF8.GetBytes('#{entropy_value}')" : ""}
              
              # Also try some fallback values
              $entropyValues += ,$null
              $entropyValues += ,[System.Text.Encoding]::UTF8.GetBytes("eryph")
              $entropyValues += ,[System.Text.Encoding]::UTF8.GetBytes("zero")
              
              $scopes = @([System.Security.Cryptography.DataProtectionScope]::CurrentUser, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
              
              foreach ($entropy in $entropyValues) {
                foreach ($scope in $scopes) {
                  try {
                    $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedBytes, $entropy, $scope)
                    $decryptedString = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
                    [System.IO.File]::WriteAllText('#{output_file.path.gsub('/', '\\')}', $decryptedString)
                    exit 0
                  } catch {
                    # Continue to next combination
                  }
                }
              }
              
              # If we get here, all combinations failed
              [System.IO.File]::WriteAllText('#{output_file.path.gsub('/', '\\')}', "ERROR: All DPAPI decryption attempts failed")
              exit 1
            } catch {
              [System.IO.File]::WriteAllText('#{output_file.path.gsub('/', '\\')}', "ERROR: $($_.Exception.Message)")
              exit 1
            }
          PS1
          
          script_file.write(script_content)
          script_file.close

          # Execute PowerShell script
          script_path = script_file.path.gsub('/', '\\')
          
          # Use spawn to execute PowerShell without shell interference
          pid = spawn("powershell.exe", "-ExecutionPolicy", "Bypass", "-NoProfile", "-File", script_path, 
                     :out => File::NULL, :err => File::NULL)
          _, status = Process.wait2(pid)
          success = status.success?
          
          # If that fails, try the full path
          unless success
            pid = spawn("C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", 
                       "-ExecutionPolicy", "Bypass", "-NoProfile", "-File", script_path,
                       :out => File::NULL, :err => File::NULL)
            _, status = Process.wait2(pid)
            success = status.success?
          end
          
          if success && File.exist?(output_file.path) && File.size(output_file.path) > 0
            result = File.read(output_file.path).strip
            # Return the result if it doesn't contain an error
            result.start_with?('ERROR:') ? nil : result
          else
            nil
          end
        rescue => e
          nil
        ensure
          temp_file.unlink if temp_file
          script_file.unlink if script_file
          output_file.unlink if output_file
        end
      end
    end
  end
end