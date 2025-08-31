# Authentication Guide

The Eryph Ruby Client uses OAuth2 with JWT assertions for authentication. This guide covers how to set up and configure authentication for different environments.

## Overview

Eryph uses OAuth2 client credentials flow with JWT assertions for API authentication. The Ruby client automatically discovers and uses configured credentials from multiple sources.

## Authentication Flow

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│ Configuration   │    │ Private Key      │    │ JWT Assertion       │
│ Discovery       │───▶│ Signing          │───▶│ Token Exchange      │
│                 │    │                  │    │                     │
│ • Multi-store   │    │ • RSA signing    │    │ • Access token      │
│ • Auto-detect   │    │ • Client claims  │    │ • Token refresh     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

## Configuration Discovery

The client searches for credentials in this order:

1. **Current Directory**: `./.eryph/{config_name}.config`
2. **User Store**: Platform-specific user directory
   - Windows: `%APPDATA%\.eryph\`
   - Unix: `~/.config/.eryph/`
3. **System Store**: Platform-specific system directory
   - Windows: `%PROGRAMDATA%\.eryph\`  
   - Unix: `/etc/.eryph/`

## Setting Up Authentication

### Step 1: Create OAuth2 Client in Eryph Identity

First, create a client in your Eryph Identity instance:

```bash
# Using Eryph PowerShell (if available)
New-EryphClient -Name "my-ruby-client" -Description "Ruby API Client"

# Or using the Identity API directly
```

This will generate:
- Client ID
- RSA private key (PEM format)
- Client certificate (for reference)

### Step 2: Create Configuration File

Create a configuration file in JSON format:

**Windows Example** (`%APPDATA%\.eryph\default.config`):
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
      "id": "client-id-from-identity",
      "name": "my-ruby-client",
      "private_key_file": "C:\\Users\\username\\.eryph\\keys\\client.key"
    }
  ],
  "default_client": "client-id-from-identity"
}
```

**Unix Example** (`~/.config/.eryph/default.config`):
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
      "id": "client-id-from-identity",
      "name": "my-ruby-client",
      "private_key_file": "/home/username/.eryph/keys/client.key"
    }
  ],
  "default_client": "client-id-from-identity"
}
```

### Step 3: Store Private Key

Save the private key to the location specified in your configuration:

**client.key** (PEM format):
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1234567890abcdef...
[Your private key content]
...
-----END RSA PRIVATE KEY-----
```

**Important Security Notes:**
- Keep private keys secure and never commit them to version control
- Use appropriate file permissions (600 on Unix systems)
- Consider using dedicated service accounts for production

## Multiple Configurations

You can manage multiple environments with different configuration files:

### Default Configuration (Remote Eryph)
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
  "clients": [...],
  "default_client": "default-client-id"
}
```

**Usage**:
```ruby
client = Eryph.compute_client('default')
# Or simply:
client = Eryph.compute_client  # Uses 'default' automatically
```

### Local Configuration (Local Eryph Instance)
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
  "clients": [...],
  "default_client": "local-client-id"
}
```

**Usage**:
```ruby
client = Eryph.compute_client('local')
```

## Special Configurations

### Eryph-Zero (Local Development)

For local development with `eryph-zero`, the client automatically discovers running instances **without any configuration files**:

**How it works:**
1. **Scans for running processes** - Checks application data directories for eryph-zero lock files
2. **Validates processes** - Confirms processes are actually running by checking PIDs
3. **Extracts endpoints** - Gets identity and compute endpoints from process metadata
4. **Uses system client** - Automatically uses system client credentials from the running instance

**Usage**:
```ruby
# Auto-discover local eryph-zero instance (Windows only)
client = Eryph.compute_client('zero')
```

**Requirements:**
- Eryph-zero running locally (Windows only)
- Administrator privileges (for system client access)
- **No configuration file needed** - auto-discovery is built-in

### System Client (Local/Zero)

For local development, system clients are automatically discovered:

```ruby
# Local configuration - may use system client as fallback (requires admin/root)
client = Eryph.compute_client('local')

# Zero configuration - automatically uses system client (Windows only, requires admin)
client = Eryph.compute_client('zero')
```

System client credentials are extracted from running Eryph processes when available.

## Authentication Verification

Test your authentication setup:

```ruby
# Test basic connection
client = Eryph.compute_client('default')
if client.test_connection
  puts "✅ Authentication successful"
else
  puts "❌ Authentication failed"
end

# Check token details
puts "Access token preview: #{client.access_token[0..20]}..."
puts "Configuration: #{client.config_name}"
```

## Advanced Configuration

### Custom SSL Settings

For development environments with self-signed certificates:

```ruby
client = Eryph.compute_client('local', 
  ssl_config: {
    verify_ssl: false,
    verify_hostname: false
  }
)
```

### Custom Scopes

Specify different OAuth2 scopes:

```ruby
client = Eryph.compute_client('default',
  scopes: ['compute:read', 'compute:write', 'projects:admin']
)
```

### Custom Logger

Use custom logging:

```ruby
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

client = Eryph.compute_client('default', logger: logger)
```

## Troubleshooting

### "No credentials found"

**Problem**: Client cannot find any configured credentials.

**Solutions**:
1. Check configuration file exists and is valid JSON
2. Verify file permissions
3. Check private key file path and permissions
4. Ensure default_client points to valid client ID

### "Invalid RSA private key"

**Problem**: Private key cannot be parsed.

**Solutions**:
1. Verify key is in PEM format
2. Check file is not corrupted
3. Ensure key matches client certificate
4. Regenerate key if necessary

### "Token request failed"

**Problem**: Cannot obtain access token from identity server.

**Solutions**:
1. Verify identity endpoint URL
2. Check client ID is registered in Identity
3. Verify private key matches registered client
4. Check network connectivity to identity server
5. Ensure client has required scopes

### "SSL verification failed"

**Problem**: SSL/TLS verification errors.

**Solutions**:
1. For development: disable SSL verification
2. For production: install proper certificates
3. Check certificate chain and root CA
4. Verify hostname matches certificate

### Permission Denied (Zero/Local)

**Problem**: Cannot access system client.

**Solutions**:
1. Run as Administrator (Windows) or root (Unix)
2. Use user-configured client instead of system client
3. Check eryph-zero is running and accessible

## Security Best Practices

1. **Private Key Security**:
   - Never commit private keys to version control
   - Use strict file permissions (600 on Unix)
   - Store keys in secure locations
   - Rotate keys regularly

2. **Configuration Management**:
   - Use separate configurations for different environments
   - Don't hardcode credentials in application code
   - Use environment variables for sensitive configuration

3. **Network Security**:
   - Use HTTPS endpoints in production
   - Validate SSL certificates in production
   - Consider network segmentation for API access

4. **Access Control**:
   - Use least-privilege principle for OAuth2 scopes
   - Monitor and audit API access
   - Use dedicated service accounts for automation

## Next Steps

- [Configuration Guide](configuration.md) - Advanced configuration management
- [Getting Started](getting-started.md) - Basic usage examples  
- [Operation Tracking](operation-tracking.md) - Advanced operation monitoring