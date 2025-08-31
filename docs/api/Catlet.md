# ComputeClient::Catlet

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **name** | **String** |  |  |
| **vm_id** | **String** | The ID of the corresponding Hyper-V virtual machine. |  |
| **project** | [**Project**](Project.md) |  |  |
| **status** | [**CatletStatus**](CatletStatus.md) |  |  |
| **networks** | [**Array&lt;CatletNetwork&gt;**](CatletNetwork.md) |  | [optional] |
| **network_adapters** | [**Array&lt;CatletNetworkAdapter&gt;**](CatletNetworkAdapter.md) |  | [optional] |
| **drives** | [**Array&lt;CatletDrive&gt;**](CatletDrive.md) |  | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::Catlet.new(
  id: null,
  name: null,
  vm_id: null,
  project: null,
  status: null,
  networks: null,
  network_adapters: null,
  drives: null
)
```

