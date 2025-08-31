# ComputeClient::CatletDrive

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | [**CatletDriveType**](CatletDriveType.md) |  |  |
| **attached_disk_id** | **String** | The ID of the actual virtual disk which is attached.  This can be null, e.g. when the VHD has been deleted,  but it is still configured in the virtual machine. | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::CatletDrive.new(
  type: null,
  attached_disk_id: null
)
```

