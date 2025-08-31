# ComputeClient::ProjectMembersApi

All URIs are relative to *https://localhost:8000/compute*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**project_members_add**](ProjectMembersApi.md#project_members_add) | **POST** /v1/projects/{project_id}/members | Add a project member |
| [**project_members_get**](ProjectMembersApi.md#project_members_get) | **GET** /v1/projects/{project_id}/members/{id} | Get a project member |
| [**project_members_list**](ProjectMembersApi.md#project_members_list) | **GET** /v1/projects/{project_id}/members | List all project members |
| [**project_members_remove**](ProjectMembersApi.md#project_members_remove) | **DELETE** /v1/projects/{project_id}/members/{id} | Remove a project member |


## project_members_add

> <Operation> project_members_add(project_id, new_project_member_body)

Add a project member

Add a project member

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::ProjectMembersApi.new
project_id = 'project_id_example' # String | 
new_project_member_body = ComputeClient::NewProjectMemberBody.new({member_id: 'member_id_example', role_id: 'role_id_example'}) # NewProjectMemberBody | 

begin
  # Add a project member
  result = api_instance.project_members_add(project_id, new_project_member_body)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectMembersApi->project_members_add: #{e}"
end
```

#### Using the project_members_add_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> project_members_add_with_http_info(project_id, new_project_member_body)

```ruby
begin
  # Add a project member
  data, status_code, headers = api_instance.project_members_add_with_http_info(project_id, new_project_member_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectMembersApi->project_members_add_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **String** |  |  |
| **new_project_member_body** | [**NewProjectMemberBody**](NewProjectMemberBody.md) |  |  |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json


## project_members_get

> <ProjectMemberRole> project_members_get(project_id, id)

Get a project member

Get a project member

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::ProjectMembersApi.new
project_id = 'project_id_example' # String | 
id = 'id_example' # String | 

begin
  # Get a project member
  result = api_instance.project_members_get(project_id, id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectMembersApi->project_members_get: #{e}"
end
```

#### Using the project_members_get_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ProjectMemberRole>, Integer, Hash)> project_members_get_with_http_info(project_id, id)

```ruby
begin
  # Get a project member
  data, status_code, headers = api_instance.project_members_get_with_http_info(project_id, id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ProjectMemberRole>
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectMembersApi->project_members_get_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **String** |  |  |
| **id** | **String** |  |  |

### Return type

[**ProjectMemberRole**](ProjectMemberRole.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## project_members_list

> <ProjectMemberRoleList> project_members_list(project_id)

List all project members

List all project members

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::ProjectMembersApi.new
project_id = 'project_id_example' # String | 

begin
  # List all project members
  result = api_instance.project_members_list(project_id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectMembersApi->project_members_list: #{e}"
end
```

#### Using the project_members_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ProjectMemberRoleList>, Integer, Hash)> project_members_list_with_http_info(project_id)

```ruby
begin
  # List all project members
  data, status_code, headers = api_instance.project_members_list_with_http_info(project_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ProjectMemberRoleList>
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectMembersApi->project_members_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **String** |  |  |

### Return type

[**ProjectMemberRoleList**](ProjectMemberRoleList.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## project_members_remove

> <Operation> project_members_remove(project_id, id)

Remove a project member

Removes a project member assignment

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::ProjectMembersApi.new
project_id = 'project_id_example' # String | 
id = 'id_example' # String | 

begin
  # Remove a project member
  result = api_instance.project_members_remove(project_id, id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectMembersApi->project_members_remove: #{e}"
end
```

#### Using the project_members_remove_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> project_members_remove_with_http_info(project_id, id)

```ruby
begin
  # Remove a project member
  data, status_code, headers = api_instance.project_members_remove_with_http_info(project_id, id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling ProjectMembersApi->project_members_remove_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **String** |  |  |
| **id** | **String** |  |  |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json

