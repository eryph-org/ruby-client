# Claude Development Guidelines for Eryph Ruby Client

## Repository Overview

### Purpose & Design

The **Eryph Ruby Client** is the official Ruby client library for the Eryph Compute API, designed for managing virtual infrastructure (catlets, virtual disks, networks, and projects). It provides a clean, idiomatic Ruby interface with built-in OAuth2 authentication using private key JWT assertions.

**Key Design Principles:**
- **Modular Architecture**: Separate runtime and compute-specific functionality
- **Configuration-based Authentication**: Automatic credential discovery from multiple sources
- **Cross-platform Support**: Windows, Linux, macOS with platform-specific paths
- **PowerShell Integration**: Seamless interoperability with Eryph PowerShell modules
- **Generated API Client**: OpenAPI-generated low-level client with high-level Ruby wrapper

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Eryph Module (lib/eryph.rb)                               │
│ - Main entry point and convenience methods                 │
│ - compute_client(), credentials_available?()               │
└─────────────────┬───────────────────────────────────────────┘
                  │
    ┌─────────────┼─────────────────────────────────────┐
    │             │                                     │
    │             ▼                                     ▼
┌───────────────────────────────┐    ┌──────────────────────────────────┐
│ Client Runtime                │    │ Compute Client                   │
│ (eryph-clientruntime gem)     │    │ (eryph-compute gem)              │
│                               │    │                                  │
│ • Authentication & Config     │    │ • High-level Compute API         │  
│ • Credential Discovery        │    │ • Resource Management            │
│ • Multi-store Configuration   │    │ • Generated OpenAPI Client       │
│ • OAuth2 Token Management     │    │ • Error Handling & Retries       │
│ • Cross-platform Paths        │    │                                  │
│ • Eryph-Zero Detection        │    │ Generated/                       │
│                               │    │ • Low-level API bindings         │
│ Components:                   │    │ • Models & Serialization         │
│ - ConfigStoresReader          │    │ • HTTP Client Configuration      │
│ - ClientCredentialsLookup     │    │                                  │
│ - TokenProvider               │    │                                  │
│ - EndpointLookup              │    │                                  │
│ - Environment (cross-platform) │   │                                  │
└───────────────────────────────┘    └──────────────────────────────────┘
```

### Project Structure

```
├── lib/
│   ├── eryph.rb                          # Main entry point with convenience methods
│   └── eryph/
│       ├── version.rb                    # Overall version
│       ├── clientruntime.rb              # Client runtime entry point
│       ├── clientruntime/                # Authentication & configuration (separate gem)
│       │   ├── version.rb
│       │   ├── environment.rb            # Cross-platform environment abstraction
│       │   ├── config_store.rb           # Single configuration store management
│       │   ├── config_stores_reader.rb   # Multi-store hierarchical configuration
│       │   ├── client_credentials_lookup.rb # Credential discovery & validation
│       │   ├── token_provider.rb         # OAuth2 token management with JWT assertions
│       │   ├── endpoint_lookup.rb        # Endpoint discovery (including eryph-zero)
│       │   └── local_identity_provider_info.rb # Eryph-zero runtime detection
│       ├── compute.rb                    # Compute client entry point
│       └── compute/
│           ├── version.rb                # Compute client version
│           ├── client.rb                 # High-level compute client wrapper
│           ├── generated.rb              # Generated client loader
│           └── generated/                # OpenAPI-generated client code
│               ├── lib/                  # Generated Ruby client
│               └── docs/                 # Generated API documentation
│
├── spec/                                 # Test suite
│   ├── spec_helper.rb                    # RSpec configuration
│   ├── integration_helper.rb             # Integration test setup
│   ├── unit/                             # Unit tests (mocked)
│   │   └── eryph/                        # Tests for each module
│   ├── integration/                      # Integration tests (real interactions)
│   │   ├── zero_configuration_spec.rb    # Eryph-zero auto-discovery tests
│   │   ├── credential_discovery_spec.rb  # Credential lookup tests
│   │   └── endpoint_configuration_spec.rb # Endpoint discovery tests
│   ├── support/                          # Test support files
│   │   ├── factories/                    # FactoryBot factories
│   │   ├── shared_examples/              # RSpec shared examples
│   │   └── vcr_cassettes/                # HTTP interaction recordings
│   └── fixtures/                         # Test data files
│
├── examples/                             # Usage examples
├── scripts/                              # Build and maintenance scripts  
├── generate.ps1 / generate.rb            # OpenAPI client generation
├── Rakefile                              # Build tasks
├── eryph-clientruntime.gemspec           # Runtime gem specification
└── eryph-compute.gemspec                 # Compute client gem specification
```

### Gem Architecture

**Two-Gem Design:**

1. **`eryph-clientruntime`**: Reusable authentication and configuration runtime
   - Can be used by future Eryph Ruby clients (identity, monitoring, etc.)
   - Handles OAuth2 JWT authentication, credential discovery, configuration management
   - Cross-platform environment abstraction

2. **`eryph-compute`**: Compute-specific client built on the runtime
   - Depends on `eryph-clientruntime`
   - Provides high-level Ruby interface to Compute API
   - Includes generated OpenAPI client for low-level operations

### Configuration System

**Multi-Store Hierarchy** (highest to lowest priority):
1. **Current Directory**: `./.eryph/{config_name}.config`
2. **User Store**: Platform-specific user config directory
3. **System Store**: Platform-specific system config directory

**Platform Paths:**
- **Windows**: `%APPDATA%\.eryph\` (user), `%PROGRAMDATA%\.eryph\` (system)
- **Unix**: `~/.config/.eryph/` (user), `/etc/.eryph/` (system)

**Special Configurations:**
- **`default`**: Primary configuration for remote instances
- **`zero`**: Auto-discovers local eryph-zero instances via runtime lock files
- **Custom configs**: User-defined configurations for different environments

### Authentication Flow

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│ Configuration   │    │ Credential       │    │ Token Provider      │
│ Discovery       │───▶│ Lookup           │───▶│ (OAuth2 JWT)        │
│                 │    │                  │    │                     │
│ • Multi-store   │    │ • Private key    │    │ • JWT assertion     │
│ • Platform paths│    │ • Client ID      │    │ • Access token      │
│ • Zero detection│    │ • Endpoints      │    │ • Token refresh     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                                                           │
                                                           ▼
                                                ┌─────────────────────┐
                                                │ API Client          │
                                                │ (Generated + Wrapper)│
                                                │                     │
                                                │ • HTTP requests     │
                                                │ • Error handling    │
                                                │ • Resource mgmt     │
                                                └─────────────────────┘
```

### Integration with PowerShell

The Ruby client is designed to work seamlessly with Eryph's PowerShell modules:

- **Configuration Compatibility**: Uses same configuration file formats and locations
- **Credential Sharing**: Can discover and use credentials created by PowerShell cmdlets
- **Consistent Behavior**: Integration tests verify Ruby and PowerShell behave identically
- **Eryph-Zero Integration**: Both clients auto-discover local development environments

### Code Generation

The low-level API client is generated using **OpenAPI Generator**:

```bash
# Regenerate from latest API specification
ruby generate.rb
# or
./generate.ps1
```

**Generated Components:**
- Ruby client classes for all API endpoints
- Model classes for request/response objects
- Documentation for all methods and models
- Configuration and authentication setup

### Development Workflow

1. **Make changes** to runtime or client code
2. **Run unit tests**: `bundle exec rspec spec/unit`
3. **Run integration tests**: `INTEGRATION_TESTS=1 bundle exec rspec spec/integration`
4. **Build gems**: `rake build_all`
5. **Test with examples**: `ruby examples/basic_usage.rb`
6. **Update generated client** (if API changed): `ruby generate.rb`

## Testing Guidelines

### 🚨 CRITICAL TESTING RULES

#### 1. NO VERBOSE/CHATTY MESSAGES IN TESTS
- **NEVER** add `puts` statements or verbose output in tests
- **NEVER** add "explanatory" messages like "PowerShell also cannot access zero config (consistent behavior)"
- Tests should be silent unless they fail
- Let the test names and assertions speak for themselves

#### 2. USE PROPER ASSERTIONS - DON'T ANALYZE IN TESTS
- Use `expect(...).to eq(...)` for exact matches
- Use `expect(...).to be_a(...)` for type checking  
- Use `expect(...).to include(...)` for array/hash inclusion
- Use `expect {...}.to raise_error(...)` for exception testing
- **DON'T** add complex analysis or data inspection inside tests
- **DON'T** add conditional logic based on test data analysis

### Test Structure

#### Environment-as-Boundary Testing Pattern

**🚨 CRITICAL TESTING MENTAL MODEL:**
- **Business Logic**: REAL (ConfigStoresReader, ClientCredentialsLookup, etc.)
- **External Dependencies**: MOCKED (Environment only)
- **When tests fail with business logic errors**: The problem is almost ALWAYS in the test setup/simulation, NOT the business logic!
- **Rule**: Business logic errors in tests are either TEST DATA errors OR real bugs in business logic

**Debug Strategy for Test Failures:**
1. **FIRST question**: "What data/files is the real code expecting?"
2. **SECOND question**: "Is TestEnvironment providing exactly that?"
3. **NEVER assume** the business logic is wrong without investigation
4. **Remember**: We're testing REAL code against SIMULATED data

#### Unit Tests (`spec/unit/`)
- Test individual classes and modules with REAL business logic
- Mock ONLY the Environment boundary (external dependencies)
- TestEnvironment must perfectly simulate what real Environment provides
- Use FactoryBot factories for test data
- Example structure:
```ruby
RSpec.describe Eryph::Compute::Client do
  let(:credentials) { build(:credentials) }
  
  describe '#initialize' do
    it 'creates client with configuration' do
      client = described_class.new('test')
      expect(client.config_name).to eq('test')
    end
  end
end
```

#### Integration Tests (`spec/integration/`)
- Test real interactions between components
- Use real PowerShell commands when needed
- Clean up test data in `after` blocks
- Use `:integration` metadata tag
- Structure integration tests with clear setup/teardown:
```ruby
RSpec.describe 'Feature Name', :integration do
  let(:test_config_name) { "test-#{SecureRandom.hex(4)}" }
  
  after do
    # Clean up test files
    cleanup_test_data(test_config_name)
  end
  
  it 'tests specific behavior' do
    # Setup
    create_test_data
    
    # Act & Assert  
    expect(actual_result).to eq(expected_result)
  end
end
```

### Test Organization

#### Factories (`spec/support/factories/`)
- Use FactoryBot for consistent test data
- Define traits for different scenarios
- Keep factories simple and focused
- Example:
```ruby
FactoryBot.define do
  factory :credentials, class: 'Eryph::ClientRuntime::ClientCredentials' do
    client_id { 'test-client-id' }
    token_endpoint { 'https://test.eryph.local/identity/connect/token' }
    
    trait :invalid do
      client_id { 'invalid-client' }
    end
  end
end
```

#### Shared Examples (`spec/support/shared_examples/`)
- Reuse common test patterns
- Test interfaces and behaviors consistently
- Example:
```ruby
RSpec.shared_examples 'an authenticated API client' do
  it 'includes authorization header' do
    expect(subject.api_client.config.access_token).to be_present
  end
end
```

### Testing Best Practices

#### ✅ DO:
- Write focused tests that test one thing
- Use descriptive test names that explain the expected behavior  
- Use `let` for lazy-loaded test data
- Use `before`/`after` hooks for setup/cleanup
- Mock external dependencies in unit tests
- Use VCR for HTTP interactions when appropriate
- Clean up test data after each test
- Test both success and failure scenarios

#### ❌ DON'T:
- Add verbose output with `puts`, `print`, or similar
- Analyze or inspect data within tests
- Write tests that depend on specific environmental conditions
- Leave test data/files after tests complete
- Test multiple unrelated behaviors in one test
- Use hard-coded values that might conflict with other tests
- Skip error handling tests

### Test Commands

Run specific test types:
```bash
# Unit tests only  
bundle exec rspec spec/unit

# Integration tests only
INTEGRATION_TESTS=1 bundle exec rspec spec/integration

# All tests
bundle exec rake spec

# Specific test file
bundle exec rspec spec/unit/eryph/compute/client_spec.rb

# Specific test with line number
bundle exec rspec spec/unit/eryph/compute/client_spec.rb:15
```

### Debugging Tests

When tests fail:
1. Read the failure message carefully
2. Check test setup and cleanup
3. Verify mocks and stubs are configured correctly
4. Use `binding.pry` for debugging (remove before committing)
5. Check for test data conflicts or environmental issues

### Configuration

- WebMock is enabled for unit tests, disabled for integration tests
- SimpleCov tracks coverage with 80% minimum
- Tests run in random order to catch dependencies
- FactoryBot methods are available in all tests
- Faker is configured for consistent data generation

## General Development Guidelines

### Code Style
- Follow Ruby conventions and existing patterns
- Use existing libraries and utilities from the codebase
- Match the established code style and formatting
- No unnecessary comments unless complex logic requires explanation

### Error Handling
- Use specific exception classes
- Provide clear error messages
- Handle expected failure scenarios gracefully
- Log errors appropriately for debugging

### Security
- Never log or expose sensitive data (keys, tokens, passwords)
- Use secure defaults for SSL/TLS configuration
- Validate inputs appropriately
- Follow security best practices for credential handling