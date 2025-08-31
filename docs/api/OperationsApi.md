# ComputeClient::OperationsApi

All URIs are relative to *https://localhost:8000/compute*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**operations_get**](OperationsApi.md#operations_get) | **GET** /v1/operations/{id} | Get an operation |
| [**operations_list**](OperationsApi.md#operations_list) | **GET** /v1/operations | List all operations |


## operations_get

> <Operation> operations_get(id, opts)

Get an operation

Get an operation

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::OperationsApi.new
id = 'id_example' # String | 
opts = {
  log_time_stamp: Time.parse('2013-10-20T19:20:30+01:00'), # Time | Filters returned log entries by the requested timestamp
  expand: 'expand_example' # String | Expand details. Supported details are: logs,resources,projects,tasks
}

begin
  # Get an operation
  result = api_instance.operations_get(id, opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling OperationsApi->operations_get: #{e}"
end
```

#### Using the operations_get_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> operations_get_with_http_info(id, opts)

```ruby
begin
  # Get an operation
  data, status_code, headers = api_instance.operations_get_with_http_info(id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling OperationsApi->operations_get_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **log_time_stamp** | **Time** | Filters returned log entries by the requested timestamp | [optional] |
| **expand** | **String** | Expand details. Supported details are: logs,resources,projects,tasks | [optional] |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## operations_list

> <OperationList> operations_list(opts)

List all operations

List all operations

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::OperationsApi.new
opts = {
  log_time_stamp: Time.parse('2013-10-20T19:20:30+01:00'), # Time | Filters returned log entries by the requested timestamp
  expand: 'expand_example' # String | Expand details. Supported details are: logs,resources,projects,tasks
}

begin
  # List all operations
  result = api_instance.operations_list(opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling OperationsApi->operations_list: #{e}"
end
```

#### Using the operations_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<OperationList>, Integer, Hash)> operations_list_with_http_info(opts)

```ruby
begin
  # List all operations
  data, status_code, headers = api_instance.operations_list_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <OperationList>
rescue ComputeClient::ApiError => e
  puts "Error when calling OperationsApi->operations_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **log_time_stamp** | **Time** | Filters returned log entries by the requested timestamp | [optional] |
| **expand** | **String** | Expand details. Supported details are: logs,resources,projects,tasks | [optional] |

### Return type

[**OperationList**](OperationList.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json

