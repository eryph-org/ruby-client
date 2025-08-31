# Eryph Compute API Reference

This directory contains the complete REST API reference documentation
generated from the OpenAPI specification.

## API Endpoints

- [CatletsApi](CatletsApi.md) - Manage virtual machines (catlets)
- [OperationsApi](OperationsApi.md) - Track long-running operations
- [ProjectsApi](ProjectsApi.md) - Manage projects
- [VirtualDisksApi](VirtualDisksApi.md) - Manage virtual disks
- [VirtualNetworksApi](VirtualNetworksApi.md) - Manage virtual networks
- [GenesApi](GenesApi.md) - Manage genes (VM templates)
- [VersionApi](VersionApi.md) - API version information

## Authentication

All API endpoints require OAuth2 authentication with JWT assertions.
See the [Authentication Guide](../guides/authentication.md) for setup instructions.

## High-Level Ruby API

For easier usage, see the [Ruby Extensions](../ruby-api/) which provide
convenient wrapper methods around these low-level API calls.
