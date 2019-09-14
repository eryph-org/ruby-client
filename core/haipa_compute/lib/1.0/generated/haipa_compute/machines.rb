# encoding: utf-8
# Code generated by Microsoft (R) AutoRest Code Generator.
# Changes may cause incorrect behavior and will be lost if the code is
# regenerated.

module Haipa::Client::Compute::V1
  #
  # Haipa management API
  #
  class Machines
    include MsRestAzure

    #
    # Creates and initializes a new instance of the Machines class.
    # @param client service class for accessing basic functionality.
    #
    def initialize(client)
      @client = client
    end

    # @return [HaipaCompute] reference to the HaipaCompute
    attr_reader :client

    #
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param filter [String] Restricts the set of items returned. The maximum
    # number of expressions is 100. The allowed functions are: allfunctions.
    # @param orderby [String] Specifies the order in which items are returned. The
    # maximum number of expressions is 5.
    # @param top [Integer] Limits the number of items returned from a collection.
    # @param skip [Integer] Excludes the specified number of items of the queried
    # collection from the result.
    # @param count [Boolean] Indicates whether the total count of items within a
    # collection are returned in the result.
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [ODataValueIEnumerableMachine] operation results.
    #
    def list(select:nil, expand:nil, filter:nil, orderby:nil, top:nil, skip:nil, count:false, custom_headers:nil)
      response = list_async(select:select, expand:expand, filter:filter, orderby:orderby, top:top, skip:skip, count:count, custom_headers:custom_headers).value!
      response.body unless response.nil?
    end

    #
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param filter [String] Restricts the set of items returned. The maximum
    # number of expressions is 100. The allowed functions are: allfunctions.
    # @param orderby [String] Specifies the order in which items are returned. The
    # maximum number of expressions is 5.
    # @param top [Integer] Limits the number of items returned from a collection.
    # @param skip [Integer] Excludes the specified number of items of the queried
    # collection from the result.
    # @param count [Boolean] Indicates whether the total count of items within a
    # collection are returned in the result.
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [MsRestAzure::AzureOperationResponse] HTTP response information.
    #
    def list_with_http_info(select:nil, expand:nil, filter:nil, orderby:nil, top:nil, skip:nil, count:false, custom_headers:nil)
      list_async(select:select, expand:expand, filter:filter, orderby:orderby, top:top, skip:skip, count:count, custom_headers:custom_headers).value!
    end

    #
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param filter [String] Restricts the set of items returned. The maximum
    # number of expressions is 100. The allowed functions are: allfunctions.
    # @param orderby [String] Specifies the order in which items are returned. The
    # maximum number of expressions is 5.
    # @param top [Integer] Limits the number of items returned from a collection.
    # @param skip [Integer] Excludes the specified number of items of the queried
    # collection from the result.
    # @param count [Boolean] Indicates whether the total count of items within a
    # collection are returned in the result.
    # @param [Hash{String => String}] A hash of custom headers that will be added
    # to the HTTP request.
    #
    # @return [Concurrent::Promise] Promise object which holds the HTTP response.
    #
    def list_async(select:nil, expand:nil, filter:nil, orderby:nil, top:nil, skip:nil, count:false, custom_headers:nil)


      request_headers = {}
      request_headers['Content-Type'] = 'application/json; charset=utf-8'

      # Set Headers
      request_headers['x-ms-client-request-id'] = SecureRandom.uuid
      request_headers['accept-language'] = @client.accept_language unless @client.accept_language.nil?
      path_template = 'odata/v1/Machines'

      request_url = @base_url || @client.base_url

      options = {
          middlewares: [[MsRest::RetryPolicyMiddleware, times: 3, retry: 0.02], [:cookie_jar]],
          query_params: {'$select' => select,'$expand' => expand,'$filter' => filter,'$orderby' => orderby,'$top' => top,'$skip' => skip,'$count' => count},
          headers: request_headers.merge(custom_headers || {}),
          base_url: request_url
      }
      promise = @client.make_request_async(:get, path_template, options)

      promise = promise.then do |result|
        http_response = result.response
        status_code = http_response.status
        response_content = http_response.body
        unless status_code == 200 || status_code == 404
          error_model = JSON.load(response_content)
          fail MsRestAzure::AzureOperationError.new(result.request, http_response, error_model)
        end

        result.request_id = http_response['x-ms-request-id'] unless http_response['x-ms-request-id'].nil?
        # Deserialize Response
        if status_code == 200
          begin
            parsed_response = response_content.to_s.empty? ? nil : JSON.load(response_content)
            result_mapper = Haipa::Client::Compute::V1::Models::ODataValueIEnumerableMachine.mapper()
            result.body = @client.deserialize(result_mapper, parsed_response)
          rescue Exception => e
            fail MsRest::DeserializationError.new('Error occurred in deserializing the response', e.message, e.backtrace, result)
          end
        end

        result
      end

      promise.execute
    end

    #
    # @param config [MachineConfig]
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [Operation] operation results.
    #
    def update_or_create(config:nil, custom_headers:nil)
      response = update_or_create_async(config:config, custom_headers:custom_headers).value!
      response.body unless response.nil?
    end

    #
    # @param config [MachineConfig]
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [MsRestAzure::AzureOperationResponse] HTTP response information.
    #
    def update_or_create_with_http_info(config:nil, custom_headers:nil)
      update_or_create_async(config:config, custom_headers:custom_headers).value!
    end

    #
    # @param config [MachineConfig]
    # @param [Hash{String => String}] A hash of custom headers that will be added
    # to the HTTP request.
    #
    # @return [Concurrent::Promise] Promise object which holds the HTTP response.
    #
    def update_or_create_async(config:nil, custom_headers:nil)


      request_headers = {}
      request_headers['Content-Type'] = 'application/json; charset=utf-8'

      # Set Headers
      request_headers['x-ms-client-request-id'] = SecureRandom.uuid
      request_headers['accept-language'] = @client.accept_language unless @client.accept_language.nil?

      # Serialize Request
      request_mapper = Haipa::Client::Compute::V1::Models::MachineConfig.mapper()
      request_content = @client.serialize(request_mapper,  config)
      request_content = request_content != nil ? JSON.generate(request_content, quirks_mode: true) : nil

      path_template = 'odata/v1/Machines'

      request_url = @base_url || @client.base_url

      options = {
          middlewares: [[MsRest::RetryPolicyMiddleware, times: 3, retry: 0.02], [:cookie_jar]],
          body: request_content,
          headers: request_headers.merge(custom_headers || {}),
          base_url: request_url
      }
      promise = @client.make_request_async(:post, path_template, options)

      promise = promise.then do |result|
        http_response = result.response
        status_code = http_response.status
        response_content = http_response.body
        unless status_code == 200
          error_model = JSON.load(response_content)
          fail MsRestAzure::AzureOperationError.new(result.request, http_response, error_model)
        end

        result.request_id = http_response['x-ms-request-id'] unless http_response['x-ms-request-id'].nil?
        # Deserialize Response
        if status_code == 200
          begin
            parsed_response = response_content.to_s.empty? ? nil : JSON.load(response_content)
            result_mapper = Haipa::Client::Compute::V1::Models::Operation.mapper()
            result.body = @client.deserialize(result_mapper, parsed_response)
          rescue Exception => e
            fail MsRest::DeserializationError.new('Error occurred in deserializing the response', e.message, e.backtrace, result)
          end
        end

        result
      end

      promise.execute
    end

    #
    # @param key
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [Machine] operation results.
    #
    def get(key, select:nil, expand:nil, custom_headers:nil)
      response = get_async(key, select:select, expand:expand, custom_headers:custom_headers).value!
      response.body unless response.nil?
    end

    #
    # @param key
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [MsRestAzure::AzureOperationResponse] HTTP response information.
    #
    def get_with_http_info(key, select:nil, expand:nil, custom_headers:nil)
      get_async(key, select:select, expand:expand, custom_headers:custom_headers).value!
    end

    #
    # @param key
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param [Hash{String => String}] A hash of custom headers that will be added
    # to the HTTP request.
    #
    # @return [Concurrent::Promise] Promise object which holds the HTTP response.
    #
    def get_async(key, select:nil, expand:nil, custom_headers:nil)
      fail ArgumentError, 'key is nil' if key.nil?


      request_headers = {}
      request_headers['Content-Type'] = 'application/json; charset=utf-8'

      # Set Headers
      request_headers['x-ms-client-request-id'] = SecureRandom.uuid
      request_headers['accept-language'] = @client.accept_language unless @client.accept_language.nil?
      path_template = 'odata/v1/Machines({key})'

      request_url = @base_url || @client.base_url

      options = {
          middlewares: [[MsRest::RetryPolicyMiddleware, times: 3, retry: 0.02], [:cookie_jar]],
          path_params: {'key' => key},
          query_params: {'$select' => select,'$expand' => expand},
          headers: request_headers.merge(custom_headers || {}),
          base_url: request_url
      }
      promise = @client.make_request_async(:get, path_template, options)

      promise = promise.then do |result|
        http_response = result.response
        status_code = http_response.status
        response_content = http_response.body
        unless status_code == 200 || status_code == 404
          error_model = JSON.load(response_content)
          fail MsRestAzure::AzureOperationError.new(result.request, http_response, error_model)
        end

        result.request_id = http_response['x-ms-request-id'] unless http_response['x-ms-request-id'].nil?
        # Deserialize Response
        if status_code == 200
          begin
            parsed_response = response_content.to_s.empty? ? nil : JSON.load(response_content)
            result_mapper = Haipa::Client::Compute::V1::Models::Machine.mapper()
            result.body = @client.deserialize(result_mapper, parsed_response)
          rescue Exception => e
            fail MsRest::DeserializationError.new('Error occurred in deserializing the response', e.message, e.backtrace, result)
          end
        end

        result
      end

      promise.execute
    end

    #
    # @param key
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [Operation] operation results.
    #
    def delete(key, custom_headers:nil)
      response = delete_async(key, custom_headers:custom_headers).value!
      response.body unless response.nil?
    end

    #
    # @param key
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [MsRestAzure::AzureOperationResponse] HTTP response information.
    #
    def delete_with_http_info(key, custom_headers:nil)
      delete_async(key, custom_headers:custom_headers).value!
    end

    #
    # @param key
    # @param [Hash{String => String}] A hash of custom headers that will be added
    # to the HTTP request.
    #
    # @return [Concurrent::Promise] Promise object which holds the HTTP response.
    #
    def delete_async(key, custom_headers:nil)
      fail ArgumentError, 'key is nil' if key.nil?


      request_headers = {}
      request_headers['Content-Type'] = 'application/json; charset=utf-8'

      # Set Headers
      request_headers['x-ms-client-request-id'] = SecureRandom.uuid
      request_headers['accept-language'] = @client.accept_language unless @client.accept_language.nil?
      path_template = 'odata/v1/Machines({key})'

      request_url = @base_url || @client.base_url

      options = {
          middlewares: [[MsRest::RetryPolicyMiddleware, times: 3, retry: 0.02], [:cookie_jar]],
          path_params: {'key' => key},
          headers: request_headers.merge(custom_headers || {}),
          base_url: request_url
      }
      promise = @client.make_request_async(:delete, path_template, options)

      promise = promise.then do |result|
        http_response = result.response
        status_code = http_response.status
        response_content = http_response.body
        unless status_code == 200
          error_model = JSON.load(response_content)
          fail MsRestAzure::AzureOperationError.new(result.request, http_response, error_model)
        end

        result.request_id = http_response['x-ms-request-id'] unless http_response['x-ms-request-id'].nil?
        # Deserialize Response
        if status_code == 200
          begin
            parsed_response = response_content.to_s.empty? ? nil : JSON.load(response_content)
            result_mapper = Haipa::Client::Compute::V1::Models::Operation.mapper()
            result.body = @client.deserialize(result_mapper, parsed_response)
          rescue Exception => e
            fail MsRest::DeserializationError.new('Error occurred in deserializing the response', e.message, e.backtrace, result)
          end
        end

        result
      end

      promise.execute
    end

    #
    # @param key
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [Operation] operation results.
    #
    def start(key, select:nil, expand:nil, custom_headers:nil)
      response = start_async(key, select:select, expand:expand, custom_headers:custom_headers).value!
      response.body unless response.nil?
    end

    #
    # @param key
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [MsRestAzure::AzureOperationResponse] HTTP response information.
    #
    def start_with_http_info(key, select:nil, expand:nil, custom_headers:nil)
      start_async(key, select:select, expand:expand, custom_headers:custom_headers).value!
    end

    #
    # @param key
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param [Hash{String => String}] A hash of custom headers that will be added
    # to the HTTP request.
    #
    # @return [Concurrent::Promise] Promise object which holds the HTTP response.
    #
    def start_async(key, select:nil, expand:nil, custom_headers:nil)
      fail ArgumentError, 'key is nil' if key.nil?


      request_headers = {}
      request_headers['Content-Type'] = 'application/json; charset=utf-8'

      # Set Headers
      request_headers['x-ms-client-request-id'] = SecureRandom.uuid
      request_headers['accept-language'] = @client.accept_language unless @client.accept_language.nil?
      path_template = 'odata/v1/Machines({key})/Start'

      request_url = @base_url || @client.base_url

      options = {
          middlewares: [[MsRest::RetryPolicyMiddleware, times: 3, retry: 0.02], [:cookie_jar]],
          path_params: {'key' => key},
          query_params: {'$select' => select,'$expand' => expand},
          headers: request_headers.merge(custom_headers || {}),
          base_url: request_url
      }
      promise = @client.make_request_async(:post, path_template, options)

      promise = promise.then do |result|
        http_response = result.response
        status_code = http_response.status
        response_content = http_response.body
        unless status_code == 200
          error_model = JSON.load(response_content)
          fail MsRestAzure::AzureOperationError.new(result.request, http_response, error_model)
        end

        result.request_id = http_response['x-ms-request-id'] unless http_response['x-ms-request-id'].nil?
        # Deserialize Response
        if status_code == 200
          begin
            parsed_response = response_content.to_s.empty? ? nil : JSON.load(response_content)
            result_mapper = Haipa::Client::Compute::V1::Models::Operation.mapper()
            result.body = @client.deserialize(result_mapper, parsed_response)
          rescue Exception => e
            fail MsRest::DeserializationError.new('Error occurred in deserializing the response', e.message, e.backtrace, result)
          end
        end

        result
      end

      promise.execute
    end

    #
    # @param key
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [Operation] operation results.
    #
    def stop(key, select:nil, expand:nil, custom_headers:nil)
      response = stop_async(key, select:select, expand:expand, custom_headers:custom_headers).value!
      response.body unless response.nil?
    end

    #
    # @param key
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param custom_headers [Hash{String => String}] A hash of custom headers that
    # will be added to the HTTP request.
    #
    # @return [MsRestAzure::AzureOperationResponse] HTTP response information.
    #
    def stop_with_http_info(key, select:nil, expand:nil, custom_headers:nil)
      stop_async(key, select:select, expand:expand, custom_headers:custom_headers).value!
    end

    #
    # @param key
    # @param select [String] Limits the properties returned in the result.
    # @param expand [String] Indicates the related entities to be represented
    # inline. The maximum depth is 2.
    # @param [Hash{String => String}] A hash of custom headers that will be added
    # to the HTTP request.
    #
    # @return [Concurrent::Promise] Promise object which holds the HTTP response.
    #
    def stop_async(key, select:nil, expand:nil, custom_headers:nil)
      fail ArgumentError, 'key is nil' if key.nil?


      request_headers = {}
      request_headers['Content-Type'] = 'application/json; charset=utf-8'

      # Set Headers
      request_headers['x-ms-client-request-id'] = SecureRandom.uuid
      request_headers['accept-language'] = @client.accept_language unless @client.accept_language.nil?
      path_template = 'odata/v1/Machines({key})/Stop'

      request_url = @base_url || @client.base_url

      options = {
          middlewares: [[MsRest::RetryPolicyMiddleware, times: 3, retry: 0.02], [:cookie_jar]],
          path_params: {'key' => key},
          query_params: {'$select' => select,'$expand' => expand},
          headers: request_headers.merge(custom_headers || {}),
          base_url: request_url
      }
      promise = @client.make_request_async(:post, path_template, options)

      promise = promise.then do |result|
        http_response = result.response
        status_code = http_response.status
        response_content = http_response.body
        unless status_code == 200
          error_model = JSON.load(response_content)
          fail MsRestAzure::AzureOperationError.new(result.request, http_response, error_model)
        end

        result.request_id = http_response['x-ms-request-id'] unless http_response['x-ms-request-id'].nil?
        # Deserialize Response
        if status_code == 200
          begin
            parsed_response = response_content.to_s.empty? ? nil : JSON.load(response_content)
            result_mapper = Haipa::Client::Compute::V1::Models::Operation.mapper()
            result.body = @client.deserialize(result_mapper, parsed_response)
          rescue Exception => e
            fail MsRest::DeserializationError.new('Error occurred in deserializing the response', e.message, e.backtrace, result)
          end
        end

        result
      end

      promise.execute
    end

  end
end
