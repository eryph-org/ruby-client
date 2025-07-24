# ComputeClient::NewVirtualDiskRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **correlation_id** | **String** |  | [optional] |
| **project_id** | **String** |  |  |
| **name** | **String** |  |  |
| **location** | **String** |  |  |
| **size** | **Integer** |  |  |
| **environment** | **String** |  | [optional] |
| **store** | **String** |  | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::NewVirtualDiskRequest.new(
  correlation_id: null,
  project_id: null,
  name: null,
  location: null,
  size: null,
  environment: null,
  store: null
)
```

