# ComputeClient::VirtualDisksApi

All URIs are relative to *https://localhost:8000/compute*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**virtual_disks_create**](VirtualDisksApi.md#virtual_disks_create) | **POST** /v1/virtualdisks | Create a virtual disk |
| [**virtual_disks_delete**](VirtualDisksApi.md#virtual_disks_delete) | **DELETE** /v1/virtualdisks/{id} | Delete a virtual disk |
| [**virtual_disks_get**](VirtualDisksApi.md#virtual_disks_get) | **GET** /v1/virtualdisks/{id} | Get a virtual disk |
| [**virtual_disks_list**](VirtualDisksApi.md#virtual_disks_list) | **GET** /v1/virtualdisks | List all virtual disks |


## virtual_disks_create

> <Operation> virtual_disks_create(opts)

Create a virtual disk

Create a virtual disk

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::VirtualDisksApi.new
opts = {
  new_virtual_disk_request: ComputeClient::NewVirtualDiskRequest.new({project_id: 'project_id_example', name: 'name_example', location: 'location_example', size: 37}) # NewVirtualDiskRequest | 
}

begin
  # Create a virtual disk
  result = api_instance.virtual_disks_create(opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualDisksApi->virtual_disks_create: #{e}"
end
```

#### Using the virtual_disks_create_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> virtual_disks_create_with_http_info(opts)

```ruby
begin
  # Create a virtual disk
  data, status_code, headers = api_instance.virtual_disks_create_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualDisksApi->virtual_disks_create_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **new_virtual_disk_request** | [**NewVirtualDiskRequest**](NewVirtualDiskRequest.md) |  | [optional] |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json


## virtual_disks_delete

> <Operation> virtual_disks_delete(id)

Delete a virtual disk

Delete a virtual disk

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::VirtualDisksApi.new
id = 'id_example' # String | 

begin
  # Delete a virtual disk
  result = api_instance.virtual_disks_delete(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualDisksApi->virtual_disks_delete: #{e}"
end
```

#### Using the virtual_disks_delete_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> virtual_disks_delete_with_http_info(id)

```ruby
begin
  # Delete a virtual disk
  data, status_code, headers = api_instance.virtual_disks_delete_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualDisksApi->virtual_disks_delete_with_http_info: #{e}"
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


## virtual_disks_get

> <VirtualDisk> virtual_disks_get(id)

Get a virtual disk

Get a virtual disk

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::VirtualDisksApi.new
id = 'id_example' # String | 

begin
  # Get a virtual disk
  result = api_instance.virtual_disks_get(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualDisksApi->virtual_disks_get: #{e}"
end
```

#### Using the virtual_disks_get_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<VirtualDisk>, Integer, Hash)> virtual_disks_get_with_http_info(id)

```ruby
begin
  # Get a virtual disk
  data, status_code, headers = api_instance.virtual_disks_get_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <VirtualDisk>
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualDisksApi->virtual_disks_get_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**VirtualDisk**](VirtualDisk.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## virtual_disks_list

> <VirtualDiskList> virtual_disks_list(opts)

List all virtual disks

List all virtual disks

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::VirtualDisksApi.new
opts = {
  project_id: 'project_id_example' # String | 
}

begin
  # List all virtual disks
  result = api_instance.virtual_disks_list(opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualDisksApi->virtual_disks_list: #{e}"
end
```

#### Using the virtual_disks_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<VirtualDiskList>, Integer, Hash)> virtual_disks_list_with_http_info(opts)

```ruby
begin
  # List all virtual disks
  data, status_code, headers = api_instance.virtual_disks_list_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <VirtualDiskList>
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualDisksApi->virtual_disks_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **String** |  | [optional] |

### Return type

[**VirtualDiskList**](VirtualDiskList.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json

