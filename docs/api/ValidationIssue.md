# ComputeClient::ValidationIssue

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **member** | **String** | The JSON path which identifies the member which has the issue.  Can be null when the issue is not related to  a specific member. | [optional] |
| **message** | **String** | The details of the issue. |  |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::ValidationIssue.new(
  member: null,
  message: null
)
```

