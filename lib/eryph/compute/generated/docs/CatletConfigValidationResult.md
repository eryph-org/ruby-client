# ComputeClient::CatletConfigValidationResult

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **is_valid** | **Boolean** | Indicates whether the catlet configuration is valid. |  |
| **errors** | [**Array&lt;ValidationIssue&gt;**](ValidationIssue.md) | Contains a list of the issues when the configuration is invalid. | [optional] |

## Example

```ruby
require 'compute_client'

instance = ComputeClient::CatletConfigValidationResult.new(
  is_valid: null,
  errors: null
)
```

