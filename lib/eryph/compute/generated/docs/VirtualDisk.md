# ComputeClient::VirtualDisk

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **name** | **String** |  |  |
| **location** | **String** |  |  |
| **data_store** | **String** |  |  |
| **project** | [**Project**](Project.md) |  |  |
| **environment** | **String** |  |  |
| **status** | [**DiskStatus**](DiskStatus.md) |  |  |
| **gene** | [**VirtualDiskGeneInfo**](VirtualDiskGeneInfo.md) |  | [optional] |
| **path** | **String** | The file system path of the virtual disk. This information  is only available to administrators. | [optional] |
| **size_bytes** | **Integer** |  | [optional] |
| **parent_id** | **String** | The ID of the parent disk when this disk is a differential disk. | [optional] |
| **parent_path** | **String** | The file system path of the virtual disk&#39;s parent. This information  is only available to administrators. The ParentPath might be populated  even if the ParentId is missing. In this case, the disk chain is corrupted. | [optional] |
| **attached_catlets** | [**Array&lt;VirtualDiskAttachedCatlet&gt;**](VirtualDiskAttachedCatlet.md) |  | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::VirtualDisk.new(
  id: null,
  name: null,
  location: null,
  data_store: null,
  project: null,
  environment: null,
  status: null,
  gene: null,
  path: null,
  size_bytes: null,
  parent_id: null,
  parent_path: null,
  attached_catlets: null
)
```

