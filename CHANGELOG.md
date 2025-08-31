# Changelog

All notable changes to the Eryph Ruby client libraries will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of Eryph Ruby compute client
- OAuth2 authentication with JWT support
- System client credential detection for eryph-zero
- Complete Compute API coverage via OpenAPI generation
- Configuration-based endpoint management
- SSL/TLS configuration support
- Comprehensive error handling and logging

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.1.0] - 2025-01-24

### Added
- Initial release of `eryph-clientruntime` gem with authentication and configuration management
- Initial release of `eryph-compute` gem with complete Compute API coverage
- Support for Windows DPAPI credential decryption
- Automatic endpoint discovery from running eryph-zero instances
- Generated API client with proper authentication
- Monorepo structure with separate versioning for runtime and compute client using changesets
- Examples and documentation for common usage patterns
- Integration with @changesets/cli for version management
- Automated version synchronization between NPM packages and Ruby gems

[Unreleased]: https://github.com/eryph-org/ruby-client/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/eryph-org/ruby-client/releases/tag/v0.1.0