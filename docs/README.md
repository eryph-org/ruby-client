# Eryph Ruby Client Libraries

Official Ruby client libraries for Eryph APIs, providing clean, idiomatic Ruby interfaces with built-in OAuth2 authentication.

## 📦 Available Gems

This is a monorepo containing multiple Eryph Ruby client libraries:

- **`eryph-compute`** - Compute API client for managing catlets, projects, and resources
- **`eryph-clientruntime`** - Shared authentication and configuration runtime
- **`eryph-identity`** *(coming soon)* - Identity API client for user and role management

## Quick Start

```ruby
require 'eryph'

# Connect to Eryph with auto-discovered configuration
client = Eryph.compute_client('zero')

# List all catlets
catlets = client.catlets.catlets_list
puts "Found #{catlets.length} catlets"

# Validate a catlet configuration
config = { name: 'test', parent: 'dbosoft/ubuntu-22.04/starter' }
result = client.validate_catlet_config(config)
puts "Configuration valid: #{result.is_valid}"
```

## 📚 Documentation

### User Guides
- [Getting Started](guides/getting-started.md) - Installation and basic setup
- [Authentication](guides/authentication.md) - OAuth2 setup and configuration
- [Configuration](guides/configuration.md) - Managing multiple environments
- [Operation Tracking](guides/operation-tracking.md) - Monitoring long-running operations

### API Reference
- [Ruby Extensions](ruby-api/) - High-level Ruby API with convenience methods
- [REST API Reference](api/) - Complete OpenAPI-generated documentation

### Examples
- [Code Examples](examples/) - Common usage patterns and recipes

## 🏗️ Architecture

The Eryph Ruby Client uses a two-layer architecture:

```
┌─────────────────────────────────────┐
│ High-Level Ruby API                 │  ← You use this
│ (Eryph::Compute::Client)           │
├─────────────────────────────────────┤
│ Generated OpenAPI Client            │  ← Generated from API spec
│ (Low-level HTTP/JSON)              │
└─────────────────────────────────────┘
```

- **High-Level API**: Convenient Ruby methods with authentication, error handling, and typed results
- **Generated Client**: Direct OpenAPI-generated bindings for complete API access

## 🔧 Key Features

- ✅ **Automatic Authentication** - OAuth2 with JWT assertions
- ✅ **Configuration Discovery** - Multi-store hierarchical configuration
- ✅ **Cross-Platform** - Windows, Linux, macOS support
- ✅ **Typed Results** - Structured result objects with Struct pattern
- ✅ **Operation Tracking** - Real-time progress monitoring
- ✅ **Error Handling** - Enhanced error messages with ProblemDetails
- ✅ **Eryph-Zero Integration** - Auto-discovery of local development environments

## 📦 Installation

Add to your Gemfile:

```ruby
gem 'eryph-compute'
```

Or install directly:

```bash
gem install eryph-compute
```

## 🚀 Next Steps

1. Check out the [Getting Started Guide](guides/getting-started.md)
2. Browse the [Code Examples](examples/)
3. Explore the [Ruby API Reference](ruby-api/)
