# ComputeClient::FloatingNetworkPort

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** |  |  |
| **provider** | **String** |  |  |
| **subnet** | **String** |  |  |
| **ip_v4_addresses** | **Array&lt;String&gt;** |  | [optional] |
| **ip_v4_subnets** | **Array&lt;String&gt;** |  | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::FloatingNetworkPort.new(
  name: null,
  provider: null,
  subnet: null,
  ip_v4_addresses: null,
  ip_v4_subnets: null
)
```

