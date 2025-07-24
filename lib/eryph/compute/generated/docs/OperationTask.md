# ComputeClient::OperationTask

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **parent_task_id** | **String** |  | [optional] |
| **name** | **String** |  |  |
| **display_name** | **String** |  | [optional] |
| **progress** | **Integer** |  |  |
| **status** | [**OperationTaskStatus**](OperationTaskStatus.md) |  |  |
| **reference** | [**OperationTaskReference**](OperationTaskReference.md) |  | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::OperationTask.new(
  id: null,
  parent_task_id: null,
  name: null,
  display_name: null,
  progress: null,
  status: null,
  reference: null
)
```

