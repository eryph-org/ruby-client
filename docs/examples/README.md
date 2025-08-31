# Examples

Code examples demonstrating common usage patterns for the Eryph Ruby Client.

## Available Examples

Code examples are located in the repository's `examples/` directory:

- **[basic_usage.rb](../../examples/basic_usage.rb)** - Getting started with the client
- **[operation_tracker_demo.rb](../../examples/operation_tracker_demo.rb)** - Advanced operation monitoring  
- **[catlet_management.rb](../../examples/catlet_management.rb)** - Complete catlet lifecycle management
- **[test_catlet_config_demo.rb](../../examples/test_catlet_config_demo.rb)** - Configuration validation examples
- **[wait_for_operation_demo.rb](../../examples/wait_for_operation_demo.rb)** - Operation waiting patterns
- **[zero_detection.rb](../../examples/zero_detection.rb)** - Eryph-zero auto-discovery

## Running Examples

Examples are available as Ruby files in the `examples/` directory:

```bash
# Basic usage
ruby examples/basic_usage.rb

# Operation tracking
ruby examples/operation_tracker_demo.rb

# Catlet management
ruby examples/catlet_management.rb

# Configuration validation
ruby examples/test_catlet_config_demo.rb

# Wait for operations
ruby examples/wait_for_operation_demo.rb

# Zero detection  
ruby examples/zero_detection.rb
```

## Quick Start

Most examples use automatic credential discovery:

```ruby
require 'eryph'

# Auto-discover configuration and credentials
client = Eryph.compute_client

# Your code here...
```

For local development with eryph-zero:

```ruby
# Use eryph-zero auto-discovery (Windows only, requires admin)
# No configuration file needed - automatically discovers running eryph-zero
client = Eryph.compute_client('zero')
```
