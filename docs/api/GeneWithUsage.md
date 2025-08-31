# ComputeClient::GeneWithUsage

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **gene_type** | [**GeneType**](GeneType.md) |  |  |
| **gene_set** | **String** |  |  |
| **name** | **String** |  |  |
| **architecture** | **String** |  |  |
| **size** | **Integer** |  |  |
| **hash** | **String** |  |  |
| **catlets** | **Array&lt;String&gt;** |  | [optional] |
| **disks** | **Array&lt;String&gt;** |  | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::GeneWithUsage.new(
  id: null,
  gene_type: null,
  gene_set: null,
  name: null,
  architecture: null,
  size: null,
  hash: null,
  catlets: null,
  disks: null
)
```

