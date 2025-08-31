# ComputeClient::VersionApi

All URIs are relative to *https://localhost:8000/compute*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**version_get**](VersionApi.md#version_get) | **GET** /v1/version | Get the API version |


## version_get

> <ApiVersionResponse> version_get

Get the API version

Gets the API version which can be used by clients for compatibility checks. This endpoint was added with eryph v0.3.

### Examples

```ruby
require 'time'
require 'compute_client'

api_instance = ComputeClient::VersionApi.new

begin
  # Get the API version
  result = api_instance.version_get
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling VersionApi->version_get: #{e}"
end
```

#### Using the version_get_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ApiVersionResponse>, Integer, Hash)> version_get_with_http_info

```ruby
begin
  # Get the API version
  data, status_code, headers = api_instance.version_get_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ApiVersionResponse>
rescue ComputeClient::ApiError => e
  puts "Error when calling VersionApi->version_get_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**ApiVersionResponse**](ApiVersionResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json

