# Eryph Ruby Compute Client

[![Gem Version](https://badge.fury.io/rb/eryph-compute-client.svg)](https://badge.fury.io/rb/eryph-compute-client)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The official Ruby client library for the Eryph Compute API. This client provides a clean, idiomatic Ruby interface to the Eryph compute infrastructure with built-in OAuth2 authentication using private key JWT assertions.

## Features

- **OAuth2 Authentication**: Secure authentication using client credentials flow with JWT assertions
- **Private Key Support**: RSA private key-based authentication following eryph security patterns
- **Environment-based Configuration**: Automatic credential discovery from environment variables
- **Modular Design**: Clean separation between generated API client and custom functionality
- **Comprehensive API Coverage**: Full access to catlets, projects, virtual disks, networks, and operations

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'eryph-compute-client'
```

And then execute:

```bash
bundle install
```

Or install it yourself with:

```bash
gem install eryph-compute-client
```

### Development Installation

For development or to use the latest code from GitHub:

```ruby
gem 'eryph-compute-client', git: 'https://github.com/eryph-org/ruby-computeclient.git'
```

## Quick Start

### Configuration-based Authentication (Recommended)

The Eryph Ruby client uses a sophisticated configuration system that automatically discovers credentials from multiple sources:

```ruby
require 'eryph'

# Create a client using the default configuration
client = Eryph.compute_client
puts "Connected!" if client.test_connection

# Use a specific configuration (e.g., for eryph-zero)
zero_client = Eryph.compute_client('zero')

# Check if credentials are available
if Eryph.credentials_available?('production')
  prod_client = Eryph.compute_client('production')
end
```

### Configuration File Setup

The client looks for configuration files in three locations (in priority order):

1. **Current Directory**: `./.eryph/{config_name}.config`
2. **User Directory**: 
   - Windows: `%APPDATA%\.eryph\{config_name}.config`
   - Unix: `~/.config/.eryph/{config_name}.config`
3. **System Directory**:
   - Windows: `%PROGRAMDATA%\.eryph\{config_name}.config`
   - Unix: `/etc/.eryph/{config_name}.config`

**Configuration File Format** (`.eryph/default.config`):
```json
{
  "endpoints": {
    "identity": "https://your-eryph-instance.com",
    "compute": "https://your-eryph-instance.com/compute"
  },
  "clients": [
    {
      "id": "your-client-id",
      "name": "My Eryph Client"
    }
  ],
  "defaultClient": "your-client-id"
}
```

**Private Key Storage** (`.eryph/private/{client-id}.key`):
```
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA...
-----END RSA PRIVATE KEY-----
```

### Direct Credentials (Legacy Support)

For backward compatibility or simple setups:

```ruby
require 'eryph'

client = Eryph.compute_client_with_credentials(
  endpoint: "https://eryph.example.com/compute",
  client_id: "your-client-id",
  private_key: File.read("private-key.pem")
)
```

### Working with Catlets

```ruby
# List all catlets
catlets = client.catlets.catlets_list
puts "Found #{catlets.value.length} catlets"

# Create a new catlet (requires generated client)
config = {
  name: "my-catlet",
  parent: "dbosoft/winsrv2019-standard/20220324",
  cpu: { count: 2 },
  memory: { startup: 1024, minimum: 512, maximum: 2048 }
}

# Note: Full API implementation requires running the generator script
# See "Code Generation" section below
```

### Working with Multiple Configurations

```ruby
# Production environment
prod_client = Eryph.compute_client('production')

# Local eryph-zero instance  
zero_client = Eryph.compute_client('zero')

# Development environment
dev_client = Eryph.compute_client('development')

# Each client uses its own configuration and credentials
```

### Eryph-Zero Detection

```ruby
require 'eryph'

# Check if eryph-zero is running
if Eryph.zero_running?
  puts "✅ Eryph-zero is running!"
  
  # Get discovered endpoints
  endpoints = Eryph.zero_endpoints
  puts "Identity: #{endpoints['identity']}"
  puts "Compute: #{endpoints['compute']}"
  
  # Create client automatically using discovered endpoints and system client
  client = Eryph.compute_client('zero')
  puts "Connected to eryph-zero!" if client.test_connection
else
  puts "❌ Eryph-zero is not running"
  puts "Start eryph-zero or use a different configuration"
end
```

### Error Handling

```ruby
begin
  client = Eryph.compute_client('production')
  result = client.catlets.some_api_call
rescue Eryph::ClientRuntime::CredentialsNotFoundError => e
  puts "Credentials not found: #{e.message}"
  puts "Please set up configuration files or use direct credentials"
rescue Eryph::ClientRuntime::TokenRequestError => e
  puts "Authentication failed: #{e.message}"
rescue Eryph::Compute::ApiError => e
  puts "API error: #{e.message}"
  puts "Response: #{e.response_body}" if e.response_body
end
```

## Documentation for API Endpoints

All URIs are relative to *https://localhost:8000/compute*

Class | Method | HTTP request | Description
------------ | ------------- | ------------- | -------------
*OpenapiClient::CatletsApi* | [**catlets_create**](docs/CatletsApi.md#catlets_create) | **POST** /v1/catlets | Create a new catlet
*OpenapiClient::CatletsApi* | [**catlets_delete**](docs/CatletsApi.md#catlets_delete) | **DELETE** /v1/catlets/{id} | Delete a catlet
*OpenapiClient::CatletsApi* | [**catlets_expand_config**](docs/CatletsApi.md#catlets_expand_config) | **POST** /v1/catlets/{id}/config/expand | Expand catlet config
*OpenapiClient::CatletsApi* | [**catlets_expand_new_config**](docs/CatletsApi.md#catlets_expand_new_config) | **POST** /v1/catlets/config/expand | Expand new catlet config
*OpenapiClient::CatletsApi* | [**catlets_get**](docs/CatletsApi.md#catlets_get) | **GET** /v1/catlets/{id} | Get a catlet
*OpenapiClient::CatletsApi* | [**catlets_get_config**](docs/CatletsApi.md#catlets_get_config) | **GET** /v1/catlets/{id}/config | Get a catlet configuration
*OpenapiClient::CatletsApi* | [**catlets_list**](docs/CatletsApi.md#catlets_list) | **GET** /v1/catlets | List all catlets
*OpenapiClient::CatletsApi* | [**catlets_populate_config_variables**](docs/CatletsApi.md#catlets_populate_config_variables) | **POST** /v1/catlets/config/populate-variables | Populate catlet config variables
*OpenapiClient::CatletsApi* | [**catlets_start**](docs/CatletsApi.md#catlets_start) | **PUT** /v1/catlets/{id}/start | Start a catlet
*OpenapiClient::CatletsApi* | [**catlets_stop**](docs/CatletsApi.md#catlets_stop) | **PUT** /v1/catlets/{id}/stop | Stop a catlet
*OpenapiClient::CatletsApi* | [**catlets_update**](docs/CatletsApi.md#catlets_update) | **PUT** /v1/catlets/{id} | Update a catlet
*OpenapiClient::CatletsApi* | [**catlets_validate_config**](docs/CatletsApi.md#catlets_validate_config) | **POST** /v1/catlets/config/validate | Validate catlet config
*OpenapiClient::GenesApi* | [**genes_cleanup**](docs/GenesApi.md#genes_cleanup) | **DELETE** /v1/genes | Remove all unused genes
*OpenapiClient::GenesApi* | [**genes_delete**](docs/GenesApi.md#genes_delete) | **DELETE** /v1/genes/{id} | Remove a gene
*OpenapiClient::GenesApi* | [**genes_get**](docs/GenesApi.md#genes_get) | **GET** /v1/genes/{id} | Get a gene
*OpenapiClient::GenesApi* | [**genes_list**](docs/GenesApi.md#genes_list) | **GET** /v1/genes | List all genes
*OpenapiClient::OperationsApi* | [**operations_get**](docs/OperationsApi.md#operations_get) | **GET** /v1/operations/{id} | Get an operation
*OpenapiClient::OperationsApi* | [**operations_list**](docs/OperationsApi.md#operations_list) | **GET** /v1/operations | List all operations
*OpenapiClient::ProjectMembersApi* | [**project_members_add**](docs/ProjectMembersApi.md#project_members_add) | **POST** /v1/projects/{project_id}/members | Add a project member
*OpenapiClient::ProjectMembersApi* | [**project_members_get**](docs/ProjectMembersApi.md#project_members_get) | **GET** /v1/projects/{project_id}/members/{id} | Get a project member
*OpenapiClient::ProjectMembersApi* | [**project_members_list**](docs/ProjectMembersApi.md#project_members_list) | **GET** /v1/projects/{project_id}/members | List all project members
*OpenapiClient::ProjectMembersApi* | [**project_members_remove**](docs/ProjectMembersApi.md#project_members_remove) | **DELETE** /v1/projects/{project_id}/members/{id} | Remove a project member
*OpenapiClient::ProjectsApi* | [**projects_create**](docs/ProjectsApi.md#projects_create) | **POST** /v1/projects | Create a new project
*OpenapiClient::ProjectsApi* | [**projects_delete**](docs/ProjectsApi.md#projects_delete) | **DELETE** /v1/projects/{id} | Delete a project
*OpenapiClient::ProjectsApi* | [**projects_get**](docs/ProjectsApi.md#projects_get) | **GET** /v1/projects/{id} | Get a project
*OpenapiClient::ProjectsApi* | [**projects_list**](docs/ProjectsApi.md#projects_list) | **GET** /v1/projects | List all projects
*OpenapiClient::VersionApi* | [**version_get**](docs/VersionApi.md#version_get) | **GET** /v1/version | Get the API version
*OpenapiClient::VirtualDisksApi* | [**virtual_disks_create**](docs/VirtualDisksApi.md#virtual_disks_create) | **POST** /v1/virtualdisks | Create a virtual disk
*OpenapiClient::VirtualDisksApi* | [**virtual_disks_delete**](docs/VirtualDisksApi.md#virtual_disks_delete) | **DELETE** /v1/virtualdisks/{id} | Delete a virtual disk
*OpenapiClient::VirtualDisksApi* | [**virtual_disks_get**](docs/VirtualDisksApi.md#virtual_disks_get) | **GET** /v1/virtualdisks/{id} | Get a virtual disk
*OpenapiClient::VirtualDisksApi* | [**virtual_disks_list**](docs/VirtualDisksApi.md#virtual_disks_list) | **GET** /v1/virtualdisks | List all virtual disks
*OpenapiClient::VirtualNetworksApi* | [**virtual_networks_get**](docs/VirtualNetworksApi.md#virtual_networks_get) | **GET** /v1/virtualnetworks/{id} | Get a virtual network
*OpenapiClient::VirtualNetworksApi* | [**virtual_networks_get_config**](docs/VirtualNetworksApi.md#virtual_networks_get_config) | **GET** /v1/projects/{project_id}/virtualnetworks/config | Get the virtual network configuration of a project
*OpenapiClient::VirtualNetworksApi* | [**virtual_networks_list**](docs/VirtualNetworksApi.md#virtual_networks_list) | **GET** /v1/virtualnetworks | List all virtual networks
*OpenapiClient::VirtualNetworksApi* | [**virtual_networks_update_config**](docs/VirtualNetworksApi.md#virtual_networks_update_config) | **PUT** /v1/projects/{project_id}/virtualnetworks/config | Update the virtual network configuration of a project


## Documentation for Models

 - [OpenapiClient::ApiVersion](docs/ApiVersion.md)
 - [OpenapiClient::ApiVersionResponse](docs/ApiVersionResponse.md)
 - [OpenapiClient::Catlet](docs/Catlet.md)
 - [OpenapiClient::CatletConfigOperationResult](docs/CatletConfigOperationResult.md)
 - [OpenapiClient::CatletConfigValidationResult](docs/CatletConfigValidationResult.md)
 - [OpenapiClient::CatletConfiguration](docs/CatletConfiguration.md)
 - [OpenapiClient::CatletDrive](docs/CatletDrive.md)
 - [OpenapiClient::CatletDriveType](docs/CatletDriveType.md)
 - [OpenapiClient::CatletList](docs/CatletList.md)
 - [OpenapiClient::CatletNetwork](docs/CatletNetwork.md)
 - [OpenapiClient::CatletNetworkAdapter](docs/CatletNetworkAdapter.md)
 - [OpenapiClient::CatletStatus](docs/CatletStatus.md)
 - [OpenapiClient::CatletStopMode](docs/CatletStopMode.md)
 - [OpenapiClient::DiskStatus](docs/DiskStatus.md)
 - [OpenapiClient::ExpandCatletConfigRequestBody](docs/ExpandCatletConfigRequestBody.md)
 - [OpenapiClient::ExpandNewCatletConfigRequest](docs/ExpandNewCatletConfigRequest.md)
 - [OpenapiClient::FloatingNetworkPort](docs/FloatingNetworkPort.md)
 - [OpenapiClient::Gene](docs/Gene.md)
 - [OpenapiClient::GeneList](docs/GeneList.md)
 - [OpenapiClient::GeneType](docs/GeneType.md)
 - [OpenapiClient::GeneWithUsage](docs/GeneWithUsage.md)
 - [OpenapiClient::NewCatletRequest](docs/NewCatletRequest.md)
 - [OpenapiClient::NewProjectMemberBody](docs/NewProjectMemberBody.md)
 - [OpenapiClient::NewProjectRequest](docs/NewProjectRequest.md)
 - [OpenapiClient::NewVirtualDiskRequest](docs/NewVirtualDiskRequest.md)
 - [OpenapiClient::Operation](docs/Operation.md)
 - [OpenapiClient::OperationList](docs/OperationList.md)
 - [OpenapiClient::OperationLogEntry](docs/OperationLogEntry.md)
 - [OpenapiClient::OperationResource](docs/OperationResource.md)
 - [OpenapiClient::OperationResult](docs/OperationResult.md)
 - [OpenapiClient::OperationStatus](docs/OperationStatus.md)
 - [OpenapiClient::OperationTask](docs/OperationTask.md)
 - [OpenapiClient::OperationTaskReference](docs/OperationTaskReference.md)
 - [OpenapiClient::OperationTaskStatus](docs/OperationTaskStatus.md)
 - [OpenapiClient::PopulateCatletConfigVariablesRequest](docs/PopulateCatletConfigVariablesRequest.md)
 - [OpenapiClient::ProblemDetails](docs/ProblemDetails.md)
 - [OpenapiClient::Project](docs/Project.md)
 - [OpenapiClient::ProjectList](docs/ProjectList.md)
 - [OpenapiClient::ProjectMemberRole](docs/ProjectMemberRole.md)
 - [OpenapiClient::ProjectMemberRoleList](docs/ProjectMemberRoleList.md)
 - [OpenapiClient::ResourceType](docs/ResourceType.md)
 - [OpenapiClient::StopCatletRequestBody](docs/StopCatletRequestBody.md)
 - [OpenapiClient::TaskReferenceType](docs/TaskReferenceType.md)
 - [OpenapiClient::UpdateCatletRequestBody](docs/UpdateCatletRequestBody.md)
 - [OpenapiClient::UpdateProjectNetworksRequestBody](docs/UpdateProjectNetworksRequestBody.md)
 - [OpenapiClient::ValidateConfigRequest](docs/ValidateConfigRequest.md)
 - [OpenapiClient::ValidationIssue](docs/ValidationIssue.md)
 - [OpenapiClient::VirtualDisk](docs/VirtualDisk.md)
 - [OpenapiClient::VirtualDiskAttachedCatlet](docs/VirtualDiskAttachedCatlet.md)
 - [OpenapiClient::VirtualDiskGeneInfo](docs/VirtualDiskGeneInfo.md)
 - [OpenapiClient::VirtualDiskList](docs/VirtualDiskList.md)
 - [OpenapiClient::VirtualNetwork](docs/VirtualNetwork.md)
 - [OpenapiClient::VirtualNetworkConfiguration](docs/VirtualNetworkConfiguration.md)
 - [OpenapiClient::VirtualNetworkList](docs/VirtualNetworkList.md)


## Configuration System

### Multi-Store Configuration Hierarchy

The Eryph Ruby client implements a hierarchical configuration system that mirrors the .NET client runtime:

1. **Current Directory Store**: `./.eryph/` (highest priority)
2. **User Store**: Platform-specific user config directory
3. **System Store**: Platform-specific system config directory (lowest priority)

### Platform-Specific Paths

| Platform | User Store | System Store |
|----------|------------|--------------|
| Windows  | `%APPDATA%\.eryph\` | `%PROGRAMDATA%\.eryph\` |
| Linux    | `~/.config/.eryph/` | `/etc/.eryph/` |
| macOS    | `~/.config/.eryph/` | `/etc/.eryph/` |

### Configuration Files

Each store can contain multiple configuration files:

- `{config_name}.config` - Main configuration (JSON format)
- `private/{client_id}.key` - RSA private key files (PEM format)

### Special Configurations

- **`default`**: Primary configuration for remote instances
- **`zero`**: Special configuration for eryph-zero (local development)
  - Automatically discovers local eryph-zero endpoints from runtime files
  - Uses system-client credentials when available
  - Fallback to manual configuration when eryph-zero is not running

### Eryph-Zero Runtime Discovery

For the `zero` configuration, the client automatically discovers running eryph-zero instances by reading runtime lock files:

**Lock File Locations:**
- **Windows**: `%PROGRAMDATA%\eryph\identity\.lock`
- **Unix**: `/var/lib/eryph/identity/.lock`

**Lock File Format:**
```json
{
  "processName": "eryph-zero",
  "processId": 12345,
  "endpoints": {
    "identity": "https://localhost:8080",
    "compute": "https://localhost:8080/compute"
  }
}
```

**System Client Discovery:**
When eryph-zero is running, the client can automatically use the system-client credentials:
- **Windows**: `%PROGRAMDATA%\eryph\identity\private\clients\system-client.key`
- **Unix**: `/var/lib/eryph/identity/private/clients/system-client.key`

## Authentication

This client uses OAuth2 client credentials flow with JWT client assertions for authentication. The JWT is signed with your RSA private key.

### Setting up Authentication

1. **Generate an RSA key pair** (if you don't have one):
   ```bash
   openssl genrsa -out private_key.pem 2048
   openssl rsa -in private_key.pem -pubout -out public_key.pem
   ```

2. **Register your client** with the Eryph identity server using the public key

3. **Configure the client** with your client ID and private key:
   ```ruby
   Eryph.configure do |config|
     config.client_id = "your-client-id"
     config.private_key_path = "/path/to/private_key.pem"
   end
   ```

### Available Scopes

- `compute:read`: Grants read access to the compute API
- `compute:write`: Grants write access to the compute API  
- `compute:catlets:read`: Grants read access for catlets
- `compute:catlets:write`: Grants write access for catlets
- `compute:catlets:control`: Grants control access (start, stop) for catlets
- `compute:genes:read`: Grants read access for genes
- `compute:genes:write`: Grants write access for genes
- `compute:projects:read`: Grants read access for projects
- `compute:projects:write`: Grants write access for projects

## Code Generation

This project uses OpenAPI Generator to create the low-level API client. To regenerate the client code:

```powershell
.\generate.ps1
```

This will:
1. Download the latest OpenAPI specification from the eryph-api-spec repository
2. Generate fresh Ruby client code
3. Place generated code in the appropriate directory structure

### Project Structure

```
lib/
├── eryph.rb                           # Main entry point
├── eryph/
│   ├── version.rb                     # Version information
│   ├── clientruntime.rb               # Client runtime entry point
│   ├── clientruntime/                 # Reusable authentication & config (separate gem)
│   │   ├── version.rb
│   │   ├── environment.rb             # Cross-platform environment abstraction
│   │   ├── config_store.rb            # Configuration file management
│   │   ├── config_stores_reader.rb    # Multi-store configuration reader
│   │   ├── client_credentials_lookup.rb # Credential discovery
│   │   ├── token_provider.rb          # OAuth2 token management
│   │   └── endpoint_lookup.rb         # Endpoint discovery
│   ├── compute.rb                     # Compute client entry point
│   ├── compute/
│   │   ├── version.rb                 # Compute client version
│   │   ├── client.rb                  # High-level compute client
│   │   └── generated/                 # Generated OpenAPI client code (via script)
│   └── ...                           # Future client modules (identity, etc.)
```

### Modular Design

- **`eryph-clientruntime`**: Reusable authentication and configuration (can be used by future identity_client, etc.)
- **`eryph-compute-client`**: Compute-specific client that depends on clientruntime
- **Generated Code**: Isolated in `compute/generated/` and regenerated via PowerShell script

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- [Issue Tracker](https://github.com/eryph-org/ruby-computeclient/issues)
- [Eryph Documentation](https://docs.eryph.io)
- [Eryph Website](https://eryph.io)

