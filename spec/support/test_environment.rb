require 'eryph/clientruntime/environment'
require 'json'
require 'openssl'

# Test implementation of Environment for unit testing
# Provides controllable external dependencies without actual file system, process, or network access
#
# 🚨 CRITICAL: This simulates the Environment for testing REAL business logic
# When tests fail with business logic errors, the problem is usually HERE (incomplete simulation), not in the business logic!
# This simulation must EXACTLY match what the real Environment would provide.
# Business logic errors in tests = either TEST DATA errors OR real bugs in business logic!
class TestEnvironment < Eryph::ClientRuntime::Environment
  def initialize
    super()
    @config_files = {}
    @private_keys = {}
    @running_processes = {}
    @dpapi_responses = {}  # For controlled DPAPI simulation
    @powershell_responses = {}  # For controlled PowerShell simulation
    @config_paths = {
      Eryph::ClientRuntime::Environment::ConfigStoreLocation::USER => '/test/user',
      Eryph::ClientRuntime::Environment::ConfigStoreLocation::SYSTEM => '/test/system', 
      Eryph::ClientRuntime::Environment::ConfigStoreLocation::CURRENT_DIRECTORY => '/test/current'
    }
    @windows = false
    @admin = false
  end

  # Configure platform behavior
  def set_windows(is_windows = true)
    @windows = is_windows
    self
  end

  def set_admin(is_admin = true)
    @admin = is_admin
    self
  end

  # Add test configuration files
  def add_config_file(path, config_hash)
    @config_files[path] = JSON.generate(config_hash)
    self
  end

  def add_raw_config_file(path, content)
    @config_files[path] = content
    self
  end

  # Add test private keys
  def add_private_key_file(path, pem_content)
    @private_keys[path] = pem_content
    self
  end


  # Override Environment methods to use test data
  def windows?
    @windows
  end

  def linux?
    !@windows
  end

  def admin_user?
    @admin
  end

  def get_config_path(location)
    @config_paths[location]
  end

  def file_exists?(path)
    @config_files.key?(path) || @private_keys.key?(path)
  end

  def read_file(path)
    content = @config_files[path] || @private_keys[path]
    raise IOError, "File not found: #{path}" unless content
    content
  end

  def read_binary_file(path)
    # For testing, binary file reading is the same as regular file reading
    read_file(path)
  end

  # Override process detection to use test data
  def process_running?(process_id, process_name = nil)
    return false unless process_id
    @running_processes.values.any? { |info| info[:pid] == process_id }
  end

  # Simulate DPAPI without real Windows APIs
  def decrypt_dpapi_data(encrypted_data, entropy = nil)
    return nil unless windows?
    cache_key = "#{encrypted_data}#{entropy}"
    @dpapi_responses[cache_key]
  end

  # Simulate PowerShell without real execution  
  def execute_powershell_script_file(script_path)
    return false unless windows?
    @powershell_responses[script_path] || false
  end

  def get_running_process_info(process_name)
    @running_processes[process_name]
  end

  def get_application_data_path(app_name = 'eryph')
    if windows?
      File.join('C:/ProgramData', app_name)
    else
      File.join('/var/lib', app_name)
    end
  end

  # Helper methods for test setup
  def add_default_config(endpoints: {}, clients: [])
    path = File.join(get_config_path(Eryph::ClientRuntime::Environment::ConfigStoreLocation::USER), '.eryph', 'default.config')
    config = {}
    config['endpoints'] = endpoints unless endpoints.empty?
    config['clients'] = clients unless clients.empty?
    add_config_file(path, config)
  end

  def add_zero_config(endpoints: {}, clients: [])
    path = File.join(get_config_path(Eryph::ClientRuntime::Environment::ConfigStoreLocation::USER), '.eryph', 'zero.config')
    config = {}
    config['endpoints'] = endpoints unless endpoints.empty?
    config['clients'] = clients unless clients.empty?
    add_config_file(path, config)
  end

  def add_client_with_key(config_name, client_id, client_name = nil, endpoints: {})
    # Add client to config
    config_path = File.join(get_config_path(Eryph::ClientRuntime::Environment::ConfigStoreLocation::USER), '.eryph', "#{config_name}.config")
    
    # Read existing config if it exists
    existing_config = {}
    if @config_files[config_path]
      existing_config = JSON.parse(@config_files[config_path])
    end
    
    # Add new client to existing clients
    existing_clients = existing_config['clients'] || []
    new_client = {
      'id' => client_id,
      'name' => client_name || client_id
    }
    
    # Remove any existing client with same ID and add new one
    existing_clients.reject! { |c| c['id'] == client_id }
    existing_clients << new_client

    config = existing_config.merge({ 
      'clients' => existing_clients,
      'defaultClientId' => existing_config['defaultClientId'] || client_id
    })
    config['endpoints'] = endpoints unless endpoints.empty?
    add_config_file(config_path, config)

    # Add corresponding private key (ConfigStore expects .key extension, not .pem)
    key_path = File.join(get_config_path(Eryph::ClientRuntime::Environment::ConfigStoreLocation::USER), '.eryph', 'private', "#{client_id}.key")
    test_key = generate_test_rsa_key
    add_private_key_file(key_path, test_key.to_pem)
    
    self
  end

  # Add running process for testing process detection
  def add_running_process(name, pid: nil, endpoints: {})
    if pid
      @running_processes[name] = { pid: pid }
    else
      @running_processes[name] = endpoints
    end
    self
  end

  # Add system client files following real Environment behavior
  def add_system_client_files(config_name, private_key:, identity_endpoint:)
    # Add metadata file
    metadata_path = File.join(get_application_data_path, config_name, 'metadata.json')
    @config_files[metadata_path] = {
      'identity_endpoint' => identity_endpoint
    }.to_json
    
    # Add private key file - behavior depends on platform like real Environment
    key_path = File.join(get_application_data_path, config_name, 'private', 'clients', 'system-client.key')
    
    if windows?
      # On Windows: store encrypted data and configure DPAPI response
      encrypted_data = "encrypted_#{private_key.hash}"
      @private_keys[key_path] = encrypted_data
      cache_key = "#{encrypted_data}#{identity_endpoint}"
      @dpapi_responses[cache_key] = private_key
    else
      # On non-Windows: store key directly in PEM format (like real Environment)
      @private_keys[key_path] = private_key
    end
    
    self
  end

  # Add zero metadata for endpoint discovery (creates .lock file)
  def add_zero_metadata(identity_endpoint: nil, compute_endpoint: nil, process_name: 'eryph-zero', process_id: nil)
    # Use a default process ID if not provided and we have a running process
    if process_id.nil?
      process_info = @running_processes[process_name]
      process_id = process_info[:pid] if process_info
    end
    
    metadata = {
      'processName' => process_name,
      'processId' => process_id,
      'endpoints' => {}
    }
    metadata['endpoints']['identity'] = identity_endpoint if identity_endpoint
    metadata['endpoints']['compute'] = compute_endpoint if compute_endpoint
    
    # Create .lock file (not metadata.json)
    lock_file_path = File.join(get_application_data_path, 'zero', '.lock')
    @config_files[lock_file_path] = metadata.to_json
    self
  end

  # Add local metadata for endpoint discovery (creates .lock file for 'local' config)
  def add_local_metadata(identity_endpoint: nil, compute_endpoint: nil, process_name: 'eryph-local', process_id: nil)
    # Use a default process ID if not provided and we have a running process
    if process_id.nil?
      process_info = @running_processes[process_name]
      process_id = process_info[:pid] if process_info
    end
    
    metadata = {
      'processName' => process_name,
      'processId' => process_id,
      'endpoints' => {}
    }
    metadata['endpoints']['identity'] = identity_endpoint if identity_endpoint
    metadata['endpoints']['compute'] = compute_endpoint if compute_endpoint
    
    # Create .lock file for local config
    lock_file_path = File.join(get_application_data_path, 'local', '.lock')
    @config_files[lock_file_path] = metadata.to_json
    self
  end

  # Configure DPAPI failure for edge case testing
  def add_dpapi_failure(encrypted_data, entropy = nil)
    cache_key = "#{encrypted_data}#{entropy}"
    @dpapi_responses[cache_key] = nil
  end

  # Configure PowerShell response for testing
  def add_powershell_response(script_path, success = true)
    @powershell_responses[script_path] = success
  end

  # Add generic lock file with JSON content
  def add_lock_file(path, metadata_hash)
    @config_files[path] = JSON.generate(metadata_hash)
    self
  end

  # Add raw lock file content (for malformed JSON testing)
  def add_raw_lock_file(path, content)
    @config_files[path] = content
    self
  end

  private

  def generate_test_rsa_key
    OpenSSL::PKey::RSA.new(2048)
  end
end