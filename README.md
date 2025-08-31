# Eryph Ruby Client Libraries

[![Gem Version](https://badge.fury.io/rb/eryph-compute.svg)](https://badge.fury.io/rb/eryph-compute)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Official Ruby client libraries for Eryph APIs with seamless OAuth2 authentication, automatic configuration discovery, and cross-platform support.

## 🚀 Quick Start

```ruby
require 'eryph'

# Automatic credential discovery - tries multiple configs in priority order  
client = Eryph.compute_client  # Auto-discovers: default → zero → local

# Or specify configuration/client explicitly
# client = Eryph.compute_client('production')           # Specific config
# client = Eryph.compute_client(client_id: 'my-app')    # Find client across all configs
# client = Eryph.compute_client('zero', client_id: 'admin')  # Specific client in config

# List your catlets
catlets = client.catlets.catlets_list
puts "Found #{catlets.value.length} catlets"

# Validate a configuration  
config = { name: 'my-app', parent: 'dbosoft/ubuntu-22.04/starter' }
result = client.validate_catlet_config(config)
puts result.is_valid ? '✅ Valid' : '❌ Invalid'
```

## 📦 Installation

Add to your Gemfile:
```ruby
gem 'eryph-compute'
```

Or install directly:
```bash
gem install eryph-compute
```

## ✨ Features

- **🔐 Zero-Config Authentication** - Automatic credential discovery from multiple sources
- **🎯 eryph-zero Integration** - Auto-detects local development environments  
- **🌍 Cross-Platform** - Windows, Linux, and macOS support
- **🔄 Operation Tracking** - Real-time monitoring of long-running operations

## 🏗️ Architecture 

This is a **monorepo** containing multiple Ruby client libraries:

| Gem | Description | Use Case |
|-----|-------------|----------|
| **`eryph-compute`** | Compute API client | Managing catlets, projects, resources |
| **`eryph-clientruntime`** | Shared authentication runtime | Used by all Eryph clients |
| **`eryph-identity`** | *Coming Soon* | User and role management |

## 📚 Documentation

### Getting Started
- **[Installation & Setup](docs/guides/getting-started.md)** - Complete installation guide
- **[Authentication](docs/guides/authentication.md)** - OAuth2 setup and configuration  
- **[Configuration](docs/guides/configuration.md)** - Managing multiple environments

### API Reference  
- **[Ruby API Reference](docs/ruby-api/)** - High-level Ruby client documentation
- **[REST API Reference](docs/api/)** - Complete OpenAPI specification
- **[Code Examples](docs/examples/)** - Common usage patterns

For detailed API endpoint documentation, see **[API Reference](docs/api/)** - complete REST API documentation with all endpoints, models, and examples.

## 🔧 Configuration

The client uses a hierarchical configuration system with automatic discovery:

```bash
# Priority order (highest to lowest):
1. ./.eryph/{config}.config          # Project directory
2. ~/.config/.eryph/{config}.config  # User directory (Unix)
   %APPDATA%\.eryph\{config}.config  # User directory (Windows)  
3. /etc/.eryph/{config}.config       # System directory (Unix)
   %PROGRAMDATA%\.eryph\{config}.config # System directory (Windows)
```

**Configuration file example** (`.eryph/default.config`):
```json
{
  "endpoints": {
    "identity": "https://identity.mycompany.com",
    "compute": "https://compute.mycompany.com"
  },
  "clients": [{
    "id": "my-app-client",
    "name": "My Application"
  }],
  "defaultClient": "my-app-client"
}
```

## 🎯 Multiple Environments & Discovery

```ruby
# Automatic discovery (recommended - tries multiple configs)
client = Eryph.compute_client  # Auto-discovers best available credentials

# Specific configurations  
prod_client = Eryph.compute_client('production')  # Production environment
dev_client = Eryph.compute_client('zero')         # Local eryph-zero instance  

# Client ID-based discovery (searches across all configurations)
admin_client = Eryph.compute_client(client_id: 'admin-client')
app_client = Eryph.compute_client(client_id: 'my-app-client')

# Combined - specific client in specific config
specific_client = Eryph.compute_client('production', client_id: 'backup-service')
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- Development setup with changeset management
- Code style and testing requirements  
- Pull request process
- Release workflow

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support & Community

- **[📖 Documentation](https://https://www.eryph.io/docs)** - Complete guides and API reference
- **[🐛 Issue Tracker](https://github.com/eryph-org/ruby-client/issues)** - Bug reports and feature requests
- **[💬 Discussions](https://github.com/eryph-org/eryph/discussions)** - Community support and questions  
- **[🌐 Website](https://eryph.io)** - Learn more about Eryph

---

<div align="center">
  <strong>Built with ❤️ by the Eryph Team</strong>
</div>