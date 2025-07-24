# ComputeClient::CatletNetwork

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** |  |  |
| **provider** | **String** |  |  |
| **ip_v4_addresses** | **Array&lt;String&gt;** |  | [optional] |
| **i_pv4_default_gateway** | **String** |  | [optional] |
| **dns_server_addresses** | **Array&lt;String&gt;** |  | [optional] |
| **ip_v4_subnets** | **Array&lt;String&gt;** |  | [optional] |
| **floating_port** | [**FloatingNetworkPort**](FloatingNetworkPort.md) |  | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::CatletNetwork.new(
  name: null,
  provider: null,
  ip_v4_addresses: null,
  i_pv4_default_gateway: null,
  dns_server_addresses: null,
  ip_v4_subnets: null,
  floating_port: null
)
```

