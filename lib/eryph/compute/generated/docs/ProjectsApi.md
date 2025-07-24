# ComputeClient::ProjectsApi

All URIs are relative to *https://localhost:8000/compute*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**projects_create**](ProjectsApi.md#projects_create) | **POST** /v1/projects | Create a new project |
| [**projects_delete**](ProjectsApi.md#projects_delete) | **DELETE** /v1/projects/{id} | Delete a project |
| [**projects_get**](ProjectsApi.md#projects_get) | **GET** /v1/projects/{id} | Get a project |
| [**projects_list**](ProjectsApi.md#projects_list) | **GET** /v1/projects | List all projects |


## projects_create

> <Operation> projects_create(opts)

Create a new project

Create a project

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::ProjectsApi.new
opts = {
  new_project_request: ComputeClient::NewProjectRequest.new({name: 'name_example'}) # NewProjectRequest | 
}

begin
  # Create a new project
  result = api_instance.projects_create(opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectsApi->projects_create: #{e}"
end
```

#### Using the projects_create_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> projects_create_with_http_info(opts)

```ruby
begin
  # Create a new project
  data, status_code, headers = api_instance.projects_create_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectsApi->projects_create_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **new_project_request** | [**NewProjectRequest**](NewProjectRequest.md) |  | [optional] |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json


## projects_delete

> <Operation> projects_delete(id)

Delete a project

Delete a project

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::ProjectsApi.new
id = 'id_example' # String | 

begin
  # Delete a project
  result = api_instance.projects_delete(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectsApi->projects_delete: #{e}"
end
```

#### Using the projects_delete_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> projects_delete_with_http_info(id)

```ruby
begin
  # Delete a project
  data, status_code, headers = api_instance.projects_delete_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectsApi->projects_delete_with_http_info: #{e}"
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


## projects_get

> <Project> projects_get(id)

Get a project

Get a project

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::ProjectsApi.new
id = 'id_example' # String | 

begin
  # Get a project
  result = api_instance.projects_get(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectsApi->projects_get: #{e}"
end
```

#### Using the projects_get_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Project>, Integer, Hash)> projects_get_with_http_info(id)

```ruby
begin
  # Get a project
  data, status_code, headers = api_instance.projects_get_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Project>
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectsApi->projects_get_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**Project**](Project.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## projects_list

> <ProjectList> projects_list

List all projects

List all projects

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::ProjectsApi.new

begin
  # List all projects
  result = api_instance.projects_list
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectsApi->projects_list: #{e}"
end
```

#### Using the projects_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ProjectList>, Integer, Hash)> projects_list_with_http_info

```ruby
begin
  # List all projects
  data, status_code, headers = api_instance.projects_list_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ProjectList>
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectsApi->projects_list_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**ProjectList**](ProjectList.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json

