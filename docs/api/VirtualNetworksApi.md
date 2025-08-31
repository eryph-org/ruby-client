# ComputeClient::VirtualNetworksApi

All URIs are relative to *https://localhost:8000/compute*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**virtual_networks_get**](VirtualNetworksApi.md#virtual_networks_get) | **GET** /v1/virtualnetworks/{id} | Get a virtual network |
| [**virtual_networks_get_config**](VirtualNetworksApi.md#virtual_networks_get_config) | **GET** /v1/projects/{project_id}/virtualnetworks/config | Get the virtual network configuration of a project |
| [**virtual_networks_list**](VirtualNetworksApi.md#virtual_networks_list) | **GET** /v1/virtualnetworks | List all virtual networks |
| [**virtual_networks_update_config**](VirtualNetworksApi.md#virtual_networks_update_config) | **PUT** /v1/projects/{project_id}/virtualnetworks/config | Update the virtual network configuration of a project |


## virtual_networks_get

> <VirtualNetwork> virtual_networks_get(id)

Get a virtual network

Get a virtual network

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::VirtualNetworksApi.new
id = 'id_example' # String | 

begin
  # Get a virtual network
  result = api_instance.virtual_networks_get(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualNetworksApi->virtual_networks_get: #{e}"
end
```

#### Using the virtual_networks_get_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<VirtualNetwork>, Integer, Hash)> virtual_networks_get_with_http_info(id)

```ruby
begin
  # Get a virtual network
  data, status_code, headers = api_instance.virtual_networks_get_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <VirtualNetwork>
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualNetworksApi->virtual_networks_get_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**VirtualNetwork**](VirtualNetwork.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## virtual_networks_get_config

> <VirtualNetworkConfiguration> virtual_networks_get_config(project_id)

Get the virtual network configuration of a project

Get the virtual network configuration of a project

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::VirtualNetworksApi.new
project_id = 'project_id_example' # String | 

begin
  # Get the virtual network configuration of a project
  result = api_instance.virtual_networks_get_config(project_id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualNetworksApi->virtual_networks_get_config: #{e}"
end
```

#### Using the virtual_networks_get_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<VirtualNetworkConfiguration>, Integer, Hash)> virtual_networks_get_config_with_http_info(project_id)

```ruby
begin
  # Get the virtual network configuration of a project
  data, status_code, headers = api_instance.virtual_networks_get_config_with_http_info(project_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <VirtualNetworkConfiguration>
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualNetworksApi->virtual_networks_get_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **String** |  |  |

### Return type

[**VirtualNetworkConfiguration**](VirtualNetworkConfiguration.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## virtual_networks_list

> <VirtualNetworkList> virtual_networks_list(opts)

List all virtual networks

List all virtual networks

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::VirtualNetworksApi.new
opts = {
  project_id: 'project_id_example' # String | 
}

begin
  # List all virtual networks
  result = api_instance.virtual_networks_list(opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualNetworksApi->virtual_networks_list: #{e}"
end
```

#### Using the virtual_networks_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<VirtualNetworkList>, Integer, Hash)> virtual_networks_list_with_http_info(opts)

```ruby
begin
  # List all virtual networks
  data, status_code, headers = api_instance.virtual_networks_list_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <VirtualNetworkList>
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualNetworksApi->virtual_networks_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **String** |  | [optional] |

### Return type

[**VirtualNetworkList**](VirtualNetworkList.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## virtual_networks_update_config

> <Operation> virtual_networks_update_config(project_id, update_project_networks_request_body)

Update the virtual network configuration of a project

Update the virtual network configuration of a project

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::VirtualNetworksApi.new
project_id = 'project_id_example' # String | 
update_project_networks_request_body = ComputeClient::UpdateProjectNetworksRequestBody.new({configuration: 3.56}) # UpdateProjectNetworksRequestBody | 

begin
  # Update the virtual network configuration of a project
  result = api_instance.virtual_networks_update_config(project_id, update_project_networks_request_body)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualNetworksApi->virtual_networks_update_config: #{e}"
end
```

#### Using the virtual_networks_update_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> virtual_networks_update_config_with_http_info(project_id, update_project_networks_request_body)

```ruby
begin
  # Update the virtual network configuration of a project
  data, status_code, headers = api_instance.virtual_networks_update_config_with_http_info(project_id, update_project_networks_request_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling VirtualNetworksApi->virtual_networks_update_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **String** |  |  |
| **update_project_networks_request_body** | [**UpdateProjectNetworksRequestBody**](UpdateProjectNetworksRequestBody.md) |  |  |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json

