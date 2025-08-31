# Contributing to Eryph Ruby Compute Client

## Development Setup

This is a monorepo containing two Ruby gems:
- `eryph-clientruntime` (authentication and configuration runtime)
- `eryph-compute` (main compute API client)

### Prerequisites

- Ruby 2.7 or higher
- Node.js 16 or higher
- pnpm (for changeset management)

### Installation

```bash
# Install Ruby dependencies
bundle install

# Install Node.js dependencies for changeset management
pnpm install
```

## Version Management

This project uses [Changesets](https://github.com/changesets/changesets) for version management. Each gem can be versioned independently.

### Making Changes

1. Make your code changes
2. Add a changeset to describe your changes:
   ```bash
   pnpm changeset
   ```
3. Follow the prompts to select which packages are affected and the type of change
4. Commit your changes and the generated changeset file

### Releasing

1. Update versions based on changesets:
   ```bash
   pnpm changeset:version
   ```
   This will:
   - Update package.json versions in the packages/ directory
   - Sync versions to Ruby version files
   - Update the CHANGELOG.md
   - Remove consumed changeset files

2. Build the gems:
   ```bash
   pnpm build:gems
   ```
   Or manually:
   ```bash
   gem build eryph-clientruntime.gemspec
   gem build eryph-compute.gemspec
   ```

3. Publish to RubyGems:
   ```bash
   pnpm changeset:publish
   ```
   Or manually:
   ```bash
   gem push eryph-clientruntime-<version>.gem
   gem push eryph-compute-<version>.gem
   ```

## Development Workflow

### Generated API Client

The compute client uses an OpenAPI-generated client. To regenerate:

```bash
pnpm generate:client
```

This runs the PowerShell script that generates the client from the OpenAPI specification.

### Testing

```bash
# Run all tests
pnpm test

# Run specific gem tests
bundle exec rake spec:clientruntime
bundle exec rake spec:compute
```

### Examples

Test the examples to ensure functionality:

```bash
ruby examples/basic_usage.rb
ruby examples/catlet_management.rb
ruby examples/zero_detection.rb
```

## Architecture

### Monorepo Structure

```
├── packages/
│   ├── clientruntime/          # NPM package for changeset (dummy)
│   └── compute-client/         # NPM package for changeset (dummy)
├── lib/
│   └── eryph/
│       ├── clientruntime/      # Authentication and config runtime
│       └── compute/            # Compute API client
├── examples/                   # Usage examples
└── scripts/                    # Build and publish scripts
```

### Version Synchronization

The monorepo uses dummy NPM packages in `packages/` for changeset management. When versions are updated:

1. Changesets updates the package.json files
2. `sync-version.js` scripts copy versions to Ruby version files
3. Gemspecs reference the Ruby version constants

This ensures the Ruby gems and NPM changeset system stay in sync.

## Publishing to RubyGems

### Requirements

1. RubyGems account with publishing permissions
2. Properly configured `gem credentials`
3. All tests passing
4. Clean git working directory

### Manual Publishing

If automated publishing fails, you can publish manually:

```bash
# Build gems
gem build eryph-clientruntime.gemspec
gem build eryph-compute.gemspec

# Publish (order matters - clientruntime first)
gem push eryph-clientruntime-<version>.gem
gem push eryph-compute-<version>.gem
```

### Versioning Strategy

- **patch**: Bug fixes, small improvements
- **minor**: New features, backwards-compatible changes  
- **major**: Breaking changes

The `eryph-compute` gem depends on `eryph-clientruntime` with a compatible version constraint (`~> x.y`).

## Common Commands

```bash
# Check changeset status
pnpm changeset:status

# Add a changeset
pnpm changeset

# Update versions
pnpm changeset:version

# Build gems
pnpm build:gems

# Publish gems
pnpm changeset:publish

# Generate API client
pnpm generate:client

# Run tests
pnpm test
```