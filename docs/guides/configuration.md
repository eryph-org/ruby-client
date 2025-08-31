# Configuration Guide

This guide covers advanced configuration management for the Eryph Ruby Client, including multi-environment setups, credential management, and configuration best practices.

## Configuration Architecture

The Eryph Ruby Client uses a hierarchical configuration system compatible with Eryph PowerShell modules:

```
┌─────────────────────────────────────────────────────────────┐
│ Configuration Priority (highest to lowest)                 │
├─────────────────────────────────────────────────────────────┤
│ 1. Current Directory: ./.eryph/{config_name}.config        │
│ 2. User Store: ~/.config/.eryph/{config_name}.config       │
│ 3. System Store: /etc/.eryph/{config_name}.config          │
└─────────────────────────────────────────────────────────────┘
```

## Configuration File Format

Configuration files use JSON format with this structure:

```json
{
  "version": "1.0",
  "identity": {
    "endpoint": "https://identity.example.com"
  },
  "compute": {
    "endpoint": "https://compute.example.com"
  },
  "clients": [
    {
      "id": "client-uuid",
      "name": "client-name",
      "private_key_file": "/path/to/private/key.pem"
    }
  ],
  "default_client": "client-uuid"
}
```

## Platform-Specific Paths

### Windows
- **User Store**: `%APPDATA%\.eryph\`
- **System Store**: `%PROGRAMDATA%\.eryph\`
- **Current Directory**: `.\.eryph\`

### Unix (Linux/macOS)
- **User Store**: `~/.config/.eryph/`
- **System Store**: `/etc/.eryph/`
- **Current Directory**: `./.eryph/`

## Configuration Discovery

### Automatic Discovery

When no configuration is specified, the client searches configurations in this order:

```ruby
# Automatic discovery
client = Eryph.compute_client

# Search order (Windows):
# 1. default.config
# 2. zero.config (if on Windows)
# 3. local.config

# Search order (Unix):
# 1. default.config
# 2. local.config
```

### Specific Configuration

```ruby
# Use specific configuration
client = Eryph.compute_client('default')

# Searches for:
# 1. ./.eryph/default.config
# 2. ~/.config/.eryph/default.config (Unix)
# 3. /etc/.eryph/default.config (Unix)
```

### Cross-Configuration Client Search

```ruby
# Find client by ID across all configurations
client = Eryph.compute_client(client_id: 'my-client-id')

# Find client in specific configuration
client = Eryph.compute_client('default', client_id: 'my-client-id')
```

## Multi-Environment Setup

### Local Environment

**File**: `~/.config/.eryph/local.config`
```json
{
  "version": "1.0",
  "identity": {
    "endpoint": "https://localhost:8080/identity"
  },
  "compute": {
    "endpoint": "https://localhost:8080/compute"
  },
  "clients": [
    {
      "id": "local-client-12345",
      "name": "local-client",
      "private_key_file": "/home/user/.eryph/keys/local-client.key"
    }
  ],
  "default_client": "local-client-12345"
}
```

### Default Environment (Remote Eryph)

**File**: `~/.config/.eryph/default.config`
```json
{
  "version": "1.0",
  "identity": {
    "endpoint": "https://identity.mycompany.com"
  },
  "compute": {
    "endpoint": "https://compute.mycompany.com"
  },
  "clients": [
    {
      "id": "default-client-67890",
      "name": "default-client",
      "private_key_file": "/home/user/.eryph/keys/default-client.key"
    }
  ],
  "default_client": "default-client-67890"
}
```

### Zero Environment (Eryph-Zero Auto-Discovery)

The `zero` configuration automatically discovers running eryph-zero instances without requiring any configuration files. It:

1. **Scans for running eryph processes** via lock files in application data directories
2. **Extracts endpoint information** from the discovered processes
3. **Uses system client credentials** automatically (requires Administrator/root privileges)
4. **Works only on Windows** where eryph-zero is supported

**No configuration file needed** - just ensure eryph-zero is running locally.

## Project-Specific Configuration

For project-specific settings, create a configuration in your project directory:

**File**: `./.eryph/project.config`
```json
{
  "version": "1.0",
  "identity": {
    "endpoint": "https://project-identity.mycompany.com"
  },
  "compute": {
    "endpoint": "https://project-compute.mycompany.com"
  },
  "clients": [
    {
      "id": "project-client-xyz789",
      "name": "project-specific-client",
      "private_key_file": "./.eryph/keys/project-client.key"
    }
  ],
  "default_client": "project-client-xyz789"
}
```

**Usage**:
```ruby
# Automatically uses project-specific configuration
client = Eryph.compute_client('project')

# Or explicit project directory configuration  
Dir.chdir('/path/to/project') do
  client = Eryph.compute_client('project')
end
```

## Multiple Clients per Configuration

You can configure multiple clients in a single configuration:

```json
{
  "version": "1.0",
  "identity": {
    "endpoint": "https://identity.mycompany.com"
  },
  "compute": {
    "endpoint": "https://compute.mycompany.com"
  },
  "clients": [
    {
      "id": "read-only-client",
      "name": "readonly",
      "private_key_file": "/path/to/readonly.key"
    },
    {
      "id": "admin-client",
      "name": "admin",
      "private_key_file": "/path/to/admin.key"
    },
    {
      "id": "service-client",
      "name": "service-account",
      "private_key_file": "/path/to/service.key"
    }
  ],
  "default_client": "read-only-client"
}
```

**Usage**:
```ruby
# Use default client (read-only)
readonly_client = Eryph.compute_client('default')

# Use specific client
admin_client = Eryph.compute_client('default', client_id: 'admin-client')
service_client = Eryph.compute_client('default', client_id: 'service-client')
```

## Eryph-Zero Configuration

For local development with eryph-zero:

The `zero` configuration automatically detects running eryph-zero instances by:

1. **Scanning lock files** in application data directories
2. **Validating running processes** by checking process IDs and names
3. **Extracting endpoints** (identity, compute) from process metadata
4. **Using system client credentials** from the running eryph-zero instance

**No configuration file is required** - the detection happens automatically when you specify `'zero'` as the configuration name.

**Usage**:
```ruby
# Auto-discover local eryph-zero
client = Eryph.compute_client('zero')

# Requires Administrator (Windows) or root (Unix) privileges
```

## Environment Variables

You can override configuration settings using environment variables:

```bash
# Override endpoints
export ERYPH_IDENTITY_ENDPOINT="https://custom-identity.com"
export ERYPH_COMPUTE_ENDPOINT="https://custom-compute.com"

# Override client settings
export ERYPH_CLIENT_ID="custom-client-id"
export ERYPH_PRIVATE_KEY_FILE="/custom/path/to/key.pem"
```

```ruby
# Environment variables take precedence
client = Eryph.compute_client('default')
```

## Configuration Validation

The client validates configurations on load:

```ruby
require 'eryph'

begin
  client = Eryph.compute_client('default')
rescue Eryph::ClientRuntime::ConfigurationError => e
  puts "Configuration error: #{e.message}"
  
  # Common issues:
  # - Missing configuration file
  # - Invalid JSON format
  # - Missing required fields
  # - Invalid endpoint URLs
end

rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts "Credentials error: #{e.message}"
  
  # Common issues:
  # - No default client specified
  # - Client ID not found
  # - Private key file missing
  # - Invalid private key format
end
```

## Configuration Management Best Practices

### 1. Environment Separation

Keep environments completely separate:

```
~/.config/.eryph/
├── default.config         # Default remote environment
└── local.config          # Local Eryph instance
# Note: zero.config not needed - auto-discovery is built-in

/etc/.eryph/              # System-wide configs (for enterprise setups)
└── default.config        # System-wide default config
```

### 2. Key Management

Organize private keys securely:

```
~/.config/.eryph/
├── keys/
│   ├── default.key       # Default environment private key
│   └── local.key        # Local environment private key
├── default.config
└── local.config
# Note: zero uses auto-discovered system client, no key file needed
```

### 3. File Permissions

Secure configuration files:

```bash
# Configuration files
chmod 600 ~/.config/.eryph/*.config

# Private keys  
chmod 600 ~/.config/.eryph/keys/*.key

# Directory permissions
chmod 700 ~/.config/.eryph
chmod 700 ~/.config/.eryph/keys
```

### 4. Version Control

Never commit sensitive files:

**.gitignore**:
```
# Eryph configuration
.eryph/
!.eryph/*.example
```

**Example configurations**:
```
.eryph/
├── default.config.example     # Template for default
└── local.config.example      # Template for local
# Note: zero.config.example not needed - no config file required
```

## Debugging Configuration

Enable debug output to troubleshoot configuration issues:

```ruby
# Enable debug logging
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

client = Eryph.compute_client('development', logger: logger)

# Or use environment variable
ENV['ERYPH_DEBUG'] = '1'
client = Eryph.compute_client('development')
```

## Migration from PowerShell

The Ruby client is compatible with PowerShell module configurations:

```powershell
# PowerShell configuration
Add-EryphConfig -Name "default" -IdentityEndpoint "https://identity.com" -ComputeEndpoint "https://compute.com"
New-EryphClient -Configuration "default" -Name "ruby-client"
```

```ruby
# Ruby client can use the same configuration
client = Eryph.compute_client('default')
```

## Advanced Configuration Options

### Custom HTTP Settings

```json
{
  "version": "1.0",
  "identity": {
    "endpoint": "https://identity.example.com"
  },
  "compute": {
    "endpoint": "https://compute.example.com"
  },
  "http": {
    "timeout": 30,
    "retries": 3,
    "verify_ssl": true,
    "ca_bundle": "/path/to/ca-bundle.pem"
  },
  "clients": [...],
  "default_client": "client-id"
}
```

### Logging Configuration

```json
{
  "version": "1.0",
  "logging": {
    "level": "INFO",
    "file": "/var/log/eryph-client.log",
    "format": "json"
  },
  "identity": {...},
  "compute": {...},
  "clients": [...],
  "default_client": "client-id"
}
```

## Troubleshooting

### Configuration Not Found

```ruby
# Check what configurations are available
require 'eryph/clientruntime'

reader = Eryph::ClientRuntime::ConfigStoresReader.new
available_configs = reader.list_available_configurations
puts "Available configurations: #{available_configs.join(', ')}"
```

### Credential Discovery Issues

```ruby
# Test credential discovery
lookup = Eryph::ClientRuntime::ClientCredentialsLookup.new(reader, 'default')

if lookup.credentials_available?
  puts "✅ Credentials found"
  creds = lookup.find_credentials
  puts "Client ID: #{creds.client_id}"
  puts "Configuration: #{creds.configuration}"
else
  puts "❌ No credentials found"
end
```

### Endpoint Validation

```ruby
# Test endpoint connectivity
require 'net/http'
require 'uri'

endpoint_uri = URI.parse('https://compute.example.com')
begin
  response = Net::HTTP.get_response(endpoint_uri.merge('/v1/version'))
  puts "Endpoint accessible: #{response.code}"
rescue => e
  puts "Endpoint error: #{e.message}"
end
```

## Next Steps

- [Authentication Guide](authentication.md) - OAuth2 setup details
- [Getting Started](getting-started.md) - Basic usage examples
- [Operation Tracking](operation-tracking.md) - Advanced operation monitoring