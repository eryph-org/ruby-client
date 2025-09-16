# Changelog

This is a monorepo containing multiple Eryph Ruby client packages. Each package maintains its own changelog:

## Packages

- **[eryph-clientruntime](./packages/clientruntime/CHANGELOG.md)** - Core authentication and configuration runtime
- **[eryph-compute](./packages/compute-client/CHANGELOG.md)** - Compute API client built on the runtime

## Usage

Each package is versioned independently using [Changesets](https://github.com/changesets/changesets).
For specific changes, please refer to the individual package changelogs linked above.

## Repository Information

- **Format**: Based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- **Versioning**: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
- **Version Management**: [@changesets/cli](https://github.com/changesets/changesets)