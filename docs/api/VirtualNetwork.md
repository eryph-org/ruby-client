# ComputeClient::VirtualNetwork

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **name** | **String** |  |  |
| **project** | [**Project**](Project.md) |  |  |
| **environment** | **String** |  |  |
| **provider_name** | **String** |  |  |
| **ip_network** | **String** |  | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::VirtualNetwork.new(
  id: null,
  name: null,
  project: null,
  environment: null,
  provider_name: null,
  ip_network: null
)
```

