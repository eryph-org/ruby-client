# ComputeClient::CatletsApi

All URIs are relative to *https://localhost:8000/compute*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**catlets_create**](CatletsApi.md#catlets_create) | **POST** /v1/catlets | Create a new catlet |
| [**catlets_delete**](CatletsApi.md#catlets_delete) | **DELETE** /v1/catlets/{id} | Delete a catlet |
| [**catlets_expand_config**](CatletsApi.md#catlets_expand_config) | **POST** /v1/catlets/{id}/config/expand | Expand catlet config |
| [**catlets_expand_new_config**](CatletsApi.md#catlets_expand_new_config) | **POST** /v1/catlets/config/expand | Expand new catlet config |
| [**catlets_get**](CatletsApi.md#catlets_get) | **GET** /v1/catlets/{id} | Get a catlet |
| [**catlets_get_config**](CatletsApi.md#catlets_get_config) | **GET** /v1/catlets/{id}/config | Get a catlet configuration |
| [**catlets_list**](CatletsApi.md#catlets_list) | **GET** /v1/catlets | List all catlets |
| [**catlets_populate_config_variables**](CatletsApi.md#catlets_populate_config_variables) | **POST** /v1/catlets/config/populate-variables | Populate catlet config variables |
| [**catlets_start**](CatletsApi.md#catlets_start) | **PUT** /v1/catlets/{id}/start | Start a catlet |
| [**catlets_stop**](CatletsApi.md#catlets_stop) | **PUT** /v1/catlets/{id}/stop | Stop a catlet |
| [**catlets_update**](CatletsApi.md#catlets_update) | **PUT** /v1/catlets/{id} | Update a catlet |
| [**catlets_validate_config**](CatletsApi.md#catlets_validate_config) | **POST** /v1/catlets/config/validate | Validate catlet config |


## catlets_create

> <Operation> catlets_create(opts)

Create a new catlet

Create a catlet

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
opts = {
  new_catlet_request: ComputeClient::NewCatletRequest.new({configuration: 3.56}) # NewCatletRequest | 
}

begin
  # Create a new catlet
  result = api_instance.catlets_create(opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_create: #{e}"
end
```

#### Using the catlets_create_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> catlets_create_with_http_info(opts)

```ruby
begin
  # Create a new catlet
  data, status_code, headers = api_instance.catlets_create_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_create_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **new_catlet_request** | [**NewCatletRequest**](NewCatletRequest.md) |  | [optional] |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json


## catlets_delete

> <Operation> catlets_delete(id)

Delete a catlet

Deletes a catlet

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
id = 'id_example' # String | 

begin
  # Delete a catlet
  result = api_instance.catlets_delete(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_delete: #{e}"
end
```

#### Using the catlets_delete_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> catlets_delete_with_http_info(id)

```ruby
begin
  # Delete a catlet
  data, status_code, headers = api_instance.catlets_delete_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_delete_with_http_info: #{e}"
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


## catlets_expand_config

> <Operation> catlets_expand_config(id, expand_catlet_config_request_body)

Expand catlet config

Expand the config for an existing catlet

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
id = 'id_example' # String | 
expand_catlet_config_request_body = ComputeClient::ExpandCatletConfigRequestBody.new({configuration: 3.56}) # ExpandCatletConfigRequestBody | 

begin
  # Expand catlet config
  result = api_instance.catlets_expand_config(id, expand_catlet_config_request_body)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_expand_config: #{e}"
end
```

#### Using the catlets_expand_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> catlets_expand_config_with_http_info(id, expand_catlet_config_request_body)

```ruby
begin
  # Expand catlet config
  data, status_code, headers = api_instance.catlets_expand_config_with_http_info(id, expand_catlet_config_request_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_expand_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **expand_catlet_config_request_body** | [**ExpandCatletConfigRequestBody**](ExpandCatletConfigRequestBody.md) |  |  |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json


## catlets_expand_new_config

> <Operation> catlets_expand_new_config(opts)

Expand new catlet config

Expand the config for a new catlet

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
opts = {
  expand_new_catlet_config_request: ComputeClient::ExpandNewCatletConfigRequest.new({configuration: 3.56}) # ExpandNewCatletConfigRequest | 
}

begin
  # Expand new catlet config
  result = api_instance.catlets_expand_new_config(opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_expand_new_config: #{e}"
end
```

#### Using the catlets_expand_new_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> catlets_expand_new_config_with_http_info(opts)

```ruby
begin
  # Expand new catlet config
  data, status_code, headers = api_instance.catlets_expand_new_config_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_expand_new_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **expand_new_catlet_config_request** | [**ExpandNewCatletConfigRequest**](ExpandNewCatletConfigRequest.md) |  | [optional] |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json


## catlets_get

> <Catlet> catlets_get(id)

Get a catlet

Get a catlet

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
id = 'id_example' # String | 

begin
  # Get a catlet
  result = api_instance.catlets_get(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_get: #{e}"
end
```

#### Using the catlets_get_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Catlet>, Integer, Hash)> catlets_get_with_http_info(id)

```ruby
begin
  # Get a catlet
  data, status_code, headers = api_instance.catlets_get_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Catlet>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_get_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**Catlet**](Catlet.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## catlets_get_config

> <CatletConfiguration> catlets_get_config(id)

Get a catlet configuration

Get the configuration of a catlet

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
id = 'id_example' # String | 

begin
  # Get a catlet configuration
  result = api_instance.catlets_get_config(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_get_config: #{e}"
end
```

#### Using the catlets_get_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<CatletConfiguration>, Integer, Hash)> catlets_get_config_with_http_info(id)

```ruby
begin
  # Get a catlet configuration
  data, status_code, headers = api_instance.catlets_get_config_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <CatletConfiguration>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_get_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**CatletConfiguration**](CatletConfiguration.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## catlets_list

> <CatletList> catlets_list(opts)

List all catlets

List all catlets

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
opts = {
  project_id: 'project_id_example' # String | 
}

begin
  # List all catlets
  result = api_instance.catlets_list(opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_list: #{e}"
end
```

#### Using the catlets_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<CatletList>, Integer, Hash)> catlets_list_with_http_info(opts)

```ruby
begin
  # List all catlets
  data, status_code, headers = api_instance.catlets_list_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <CatletList>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **project_id** | **String** |  | [optional] |

### Return type

[**CatletList**](CatletList.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json, application/problem+json


## catlets_populate_config_variables

> <Operation> catlets_populate_config_variables(opts)

Populate catlet config variables

Populates the variables in a config for a new catlet based on the parent.

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
opts = {
  populate_catlet_config_variables_request: ComputeClient::PopulateCatletConfigVariablesRequest.new({configuration: 3.56}) # PopulateCatletConfigVariablesRequest | 
}

begin
  # Populate catlet config variables
  result = api_instance.catlets_populate_config_variables(opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_populate_config_variables: #{e}"
end
```

#### Using the catlets_populate_config_variables_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> catlets_populate_config_variables_with_http_info(opts)

```ruby
begin
  # Populate catlet config variables
  data, status_code, headers = api_instance.catlets_populate_config_variables_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_populate_config_variables_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **populate_catlet_config_variables_request** | [**PopulateCatletConfigVariablesRequest**](PopulateCatletConfigVariablesRequest.md) |  | [optional] |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json


## catlets_start

> <Operation> catlets_start(id)

Start a catlet

Start a catlet

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
id = 'id_example' # String | 

begin
  # Start a catlet
  result = api_instance.catlets_start(id)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_start: #{e}"
end
```

#### Using the catlets_start_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> catlets_start_with_http_info(id)

```ruby
begin
  # Start a catlet
  data, status_code, headers = api_instance.catlets_start_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_start_with_http_info: #{e}"
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


## catlets_stop

> <Operation> catlets_stop(id, stop_catlet_request_body)

Stop a catlet

Stop a catlet

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
id = 'id_example' # String | 
stop_catlet_request_body = ComputeClient::StopCatletRequestBody.new({mode: ComputeClient::CatletStopMode::SHUTDOWN}) # StopCatletRequestBody | 

begin
  # Stop a catlet
  result = api_instance.catlets_stop(id, stop_catlet_request_body)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_stop: #{e}"
end
```

#### Using the catlets_stop_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> catlets_stop_with_http_info(id, stop_catlet_request_body)

```ruby
begin
  # Stop a catlet
  data, status_code, headers = api_instance.catlets_stop_with_http_info(id, stop_catlet_request_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_stop_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **stop_catlet_request_body** | [**StopCatletRequestBody**](StopCatletRequestBody.md) |  |  |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json


## catlets_update

> <Operation> catlets_update(id, update_catlet_request_body)

Update a catlet

Update a catlet

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
id = 'id_example' # String | 
update_catlet_request_body = ComputeClient::UpdateCatletRequestBody.new({configuration: 3.56}) # UpdateCatletRequestBody | 

begin
  # Update a catlet
  result = api_instance.catlets_update(id, update_catlet_request_body)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_update: #{e}"
end
```

#### Using the catlets_update_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<Operation>, Integer, Hash)> catlets_update_with_http_info(id, update_catlet_request_body)

```ruby
begin
  # Update a catlet
  data, status_code, headers = api_instance.catlets_update_with_http_info(id, update_catlet_request_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <Operation>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_update_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **update_catlet_request_body** | [**UpdateCatletRequestBody**](UpdateCatletRequestBody.md) |  |  |

### Return type

[**Operation**](Operation.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json


## catlets_validate_config

> <CatletConfigValidationResult> catlets_validate_config(opts)

Validate catlet config

Performs a quick validation of the catlet configuration

### Examples

```ruby
require 'time'
require 'compute_client'
# setup authorization
ComputeClient.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = 'YOUR ACCESS TOKEN'
end

api_instance = ComputeClient::CatletsApi.new
opts = {
  validate_config_request: ComputeClient::ValidateConfigRequest.new({configuration: 3.56}) # ValidateConfigRequest | 
}

begin
  # Validate catlet config
  result = api_instance.catlets_validate_config(opts)
  p result
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_validate_config: #{e}"
end
```

#### Using the catlets_validate_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<CatletConfigValidationResult>, Integer, Hash)> catlets_validate_config_with_http_info(opts)

```ruby
begin
  # Validate catlet config
  data, status_code, headers = api_instance.catlets_validate_config_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <CatletConfigValidationResult>
rescue ComputeClient::ApiError => e
  puts "Error when calling CatletsApi->catlets_validate_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **validate_config_request** | [**ValidateConfigRequest**](ValidateConfigRequest.md) |  | [optional] |

### Return type

[**CatletConfigValidationResult**](CatletConfigValidationResult.md)

### Authorization

[oauth2](../README.md#oauth2)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json, application/problem+json

