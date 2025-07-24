require 'rbconfig'

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
          # Check if running as administrator on Windows
          # This is a simplified check - in production you might want to use Win32 APIs
          ENV['SESSIONNAME'] == 'Console' && ENV['USERNAME'] != ENV['COMPUTERNAME'] + '$'
        else
          # Check if running as root on Unix-like systems
          Process.uid == 0
        end
      end

      private

      def user_config_path
        if windows?
          # Windows: Use APPDATA
          ENV['APPDATA'] || File.expand_path('~/AppData/Roaming')
        else
          # Unix-like: Use XDG_CONFIG_HOME or fallback to ~/.config
          ENV['XDG_CONFIG_HOME'] || File.expand_path('~/.config')
        end
      end

      def system_config_path
        if windows?
          # Windows: Use PROGRAMDATA
          ENV['PROGRAMDATA'] || 'C:/ProgramData'
        else
          # Unix-like: Use /etc
          '/etc'
        end
      end
    end
  end
end