# ComputeClient::GenesApi

All URIs are relative to *https://localhost:8000/compute*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**genes_cleanup**](GenesApi.md#genes_cleanup) | **DELETE** /v1/genes | Remove all unused genes |
| [**genes_delete**](GenesApi.md#genes_delete) | **DELETE** /v1/genes/{id} | Remove a gene |
| [**genes_get**](GenesApi.md#genes_get) | **GET** /v1/genes/{id} | Get a gene |
| [**genes_list**](GenesApi.md#genes_list) | **GET** /v1/genes | List all genes |


## genes_cleanup

> <Operation> genes_cleanup

Remove all unused genes

Remove all unused genes from the local gene pool

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::GenesApi.new

begin
  # Remove all unused genes
  result = api_instance.genes_cleanup
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling GenesApi->genes_cleanup: #{e}"
end
```

#### Using the genes_cleanup_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> genes_cleanup_with_http_info

```ruby
begin
  # Remove all unused genes
  data, status_code, headers = api_instance.genes_cleanup_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling GenesApi->genes_cleanup_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## genes_delete

> <Operation> genes_delete(id)

Remove a gene

Remove a gene from the local gene pool

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::GenesApi.new
id = 'id_example' # String | 

begin
  # Remove a gene
  result = api_instance.genes_delete(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling GenesApi->genes_delete: #{e}"
end
```

#### Using the genes_delete_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> genes_delete_with_http_info(id)

```ruby
begin
  # Remove a gene
  data, status_code, headers = api_instance.genes_delete_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling GenesApi->genes_delete_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## genes_get

> <GeneWithUsage> genes_get(id)

Get a gene

Get a gene

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::GenesApi.new
id = 'id_example' # String | 

begin
  # Get a gene
  result = api_instance.genes_get(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling GenesApi->genes_get: #{e}"
end
```

#### Using the genes_get_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GeneWithUsage>, Integer, Hash)> genes_get_with_http_info(id)

```ruby
begin
  # Get a gene
  data, status_code, headers = api_instance.genes_get_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GeneWithUsage>
rescue ComputeClient::ApiError => e
  puts "Error when calling GenesApi->genes_get_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**GeneWithUsage**](GeneWithUsage.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## genes_list

> <GeneList> genes_list

List all genes

List all genes

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::GenesApi.new

begin
  # List all genes
  result = api_instance.genes_list
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling GenesApi->genes_list: #{e}"
end
```

#### Using the genes_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GeneList>, Integer, Hash)> genes_list_with_http_info

```ruby
begin
  # List all genes
  data, status_code, headers = api_instance.genes_list_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GeneList>
rescue ComputeClient::ApiError => e
  puts "Error when calling GenesApi->genes_list_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**GeneList**](GeneList.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json

