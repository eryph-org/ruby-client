# ComputeClient::Operation

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **status** | [**OperationStatus**](OperationStatus.md) |  |  |
| **status_message** | **String** |  | [optional] |
| **resources** | [**Array&lt;OperationResource&gt;**](OperationResource.md) |  | [optional] |
| **log_entries** | [**Array&lt;OperationLogEntry&gt;**](OperationLogEntry.md) |  | [optional] |
| **projects** | [**Array&lt;Project&gt;**](Project.md) |  | [optional] |
| **tasks** | [**Array&lt;OperationTask&gt;**](OperationTask.md) |  | [optional] |
| **result** | [**OperationResult**](OperationResult.md) |  | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::Operation.new(
  id: null,
  status: null,
  status_message: null,
  resources: null,
  log_entries: null,
  projects: null,
  tasks: null,
  result: null
)
```

