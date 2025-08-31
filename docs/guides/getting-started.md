# Getting Started with Eryph Ruby Client

Welcome to the Eryph Ruby Client! This guide will help you install, configure, and start using the client to manage your Eryph infrastructure.

## Installation

### Add to Gemfile

Add the Eryph Ruby Client to your `Gemfile`:

```ruby
gem 'eryph-compute'
```

Then run:

```bash
bundle install
```

### Direct Installation

Or install directly:

```bash
gem install eryph-compute
```

## Quick Start

### 1. Basic Usage with Auto-Discovery

The simplest way to get started is with automatic credential discovery:

```ruby
require 'eryph'

# Auto-discover configuration and credentials
client = Eryph.compute_client

# List all catlets
catlets = client.catlets.catlets_list
puts "Found #{catlets.length} catlets"
```

### 2. Using Specific Configuration

If you have multiple configurations, you can specify which one to use:

```ruby
# Use a specific configuration (e.g., 'default', 'zero', 'local')
client = Eryph.compute_client('default')
```

### 3. Using Specific Client

If you have multiple clients in a configuration:

```ruby
# Use specific client ID, search across all configurations
client = Eryph.compute_client(client_id: 'my-client-id')

# Use specific client in specific configuration
client = Eryph.compute_client('default', client_id: 'my-client-id')
```

## Basic Operations

### List Resources

```ruby
# List all catlets
catlets = client.catlets.catlets_list
puts "Catlets: #{catlets.map(&:name).join(', ')}"

# List projects
projects = client.projects.projects_list
puts "Projects: #{projects.map(&:name).join(', ')}"

# List virtual disks
disks = client.virtual_disks.virtual_disks_list
puts "Virtual Disks: #{disks.map(&:name).join(', ')}"
```

### Validate Configuration

```ruby
# Validate a catlet configuration
config = {
  name: 'test-catlet',
  parent: 'dbosoft/ubuntu-22.04/starter',
  cpu: { count: 2 },
  memory: { startup: 2048 }
}

result = client.validate_catlet_config(config)
if result.is_valid
  puts "✅ Configuration is valid"
else
  puts "❌ Configuration errors:"
  result.errors.each { |error| puts "  - #{error.message}" }
end
```

### Create and Track Operations

```ruby
# Create a new catlet
new_catlet_request = {
  name: 'my-new-catlet',
  project: 'default',
  config: {
    parent: 'dbosoft/ubuntu-22.04/starter'
  }
}

operation = client.catlets.catlets_create(new_catlet_request: new_catlet_request)

# Wait for completion with progress tracking
result = client.wait_for_operation(operation.id) do |event_type, data|
  case event_type
  when :log_entry
    puts "[LOG] #{data.message}"
  when :status
    puts "Status: #{data.status}"
  end
end

if result.succeeded?
  puts "✅ Catlet created successfully!"
  catlet = result.typed_result
  puts "New catlet ID: #{catlet.id}" if result.result_type == 'Catlet'
else
  puts "❌ Operation failed: #{result.status_message}"
end
```

## Error Handling

The client provides enhanced error handling with detailed problem information:

```ruby
begin
  # Some operation that might fail
  result = client.catlets.catlets_get('non-existent-id')
rescue Eryph::Compute::ProblemDetailsError => e
  puts "API Error: #{e.title}"
  puts "Detail: #{e.detail}"
  puts "Status: #{e.status}"
  
  # Access additional problem details
  if e.errors
    puts "Validation errors:"
    e.errors.each { |field, messages| puts "  #{field}: #{messages.join(', ')}" }
  end
rescue => e
  puts "Unexpected error: #{e.message}"
end
```

## Configuration Requirements

Before using the client, you need:

1. **Eryph Instance**: A running Eryph compute instance
2. **Client Credentials**: OAuth2 client configured in Eryph Identity
3. **Configuration**: Client credentials stored in configuration files

See the [Authentication Guide](authentication.md) for detailed setup instructions.

## Next Steps

- [Authentication Setup](authentication.md) - Configure OAuth2 credentials
- [Configuration Management](configuration.md) - Manage multiple environments
- [Operation Tracking](operation-tracking.md) - Advanced operation monitoring
- [API Reference](../ruby-api/) - Complete method documentation
- [Examples](../examples/) - More code examples

## Common Issues

### "No credentials found"

If you see this error, you need to configure client credentials. See the [Authentication Guide](authentication.md).

### "Connection refused"

Check that your Eryph instance is running and accessible at the configured endpoint.

### "SSL verification failed"

For development environments with self-signed certificates, you can disable SSL verification:

```ruby
client = Eryph.compute_client('local', ssl_config: { verify_ssl: false })
```

## Support

- [GitHub Issues](https://github.com/eryph-org/eryph/issues) - Bug reports and feature requests
- [Documentation](../README.md) - Full documentation index
- [Examples](../examples/) - Working code examples