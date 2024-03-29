# encoding: utf-8
# Copyright (c) dbosoft GmbH and Haipa Contributors. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

module Haipa::Client
  #
  # Class which represents a state of Haipa long running operation.
  #
  class PollingState

    # @return [Net::HTTPRequest] the HTTP request.
  	attr_accessor :request

    # @return the resource
  	attr_accessor :resource

    # @return [Net::HTTPResponse] the HTTP response.
    attr_accessor :response

    # @return [HaipaOperationError] the Haipa error data.
    attr_accessor :error_data

    # @return [String] the latest value captured from Haipa-AsyncOperation header.
    attr_accessor :Haipa_async_operation_header_link

    # @return [String] the latest value captured from Location header.
    attr_accessor :location_header_link

    # @return [String] status of the long running operation.
    attr_accessor :status

    def initialize(haipa_response, retry_timeout)
      @retry_timeout = retry_timeout
      @request = haipa_response.request
      update_response(haipa_response.response)
      @resource = haipa_response.body

      case @response.status
        when 200
          provisioning_state = get_provisioning_state
          @status = provisioning_state.nil?? (AsyncOperationStatus::SUCCESS_STATUS):provisioning_state
        when 201
          provisioning_state = get_provisioning_state
          @status = provisioning_state.nil?? (AsyncOperationStatus::IN_PROGRESS_STATUS):provisioning_state
        when 202
          @status = AsyncOperationStatus::IN_PROGRESS_STATUS
        when 204
          @status = AsyncOperationStatus::SUCCESS_STATUS
        else
          @status = AsyncOperationStatus::FAILED_STATUS
      end
    end

    #
    # Returns the provisioning status of the resource
    #
    # @return [String] provisioning status of the resource
    def get_provisioning_state
      # On non flattened resource, we should find provisioning_state inside 'properties'
      if (!@resource.nil? && @resource.respond_to?(:properties) && @resource.properties.respond_to?(:provisioning_state) && !@resource.properties.provisioning_state.nil?)
        @resource.properties.provisioning_state
        # On flattened resource, we should find provisioning_state at the top level
      elsif !@resource.nil? && @resource.respond_to?(:provisioning_state) && !@resource.provisioning_state.nil?
        @resource.provisioning_state
      else
        nil
      end
    end

    #
    # Returns the amount of time in seconds for long running operation polling delay.
    #
    # @return [Integer] Amount of time in seconds for long running operation polling delay.
    def get_delay
      return @retry_timeout unless @retry_timeout.nil?

      if !response.nil? && !response.headers['Retry-After'].nil?
        return response.headers['Retry-After'].to_i
      end

      return AsyncOperationStatus::DEFAULT_DELAY
    end

    #
    # Updates the polling state from the fields of given response object.
    # @param response [Net::HTTPResponse] the HTTP response.
    def update_response(response)
      @response = response

      unless response.nil?
        @Haipa_async_operation_header_link = response.headers['Haipa-AsyncOperation'] unless response.headers['Haipa-AsyncOperation'].nil?
        @location_header_link = response.headers['Location'] unless response.headers['Location'].nil?
      end
    end

    #
    # returns the Haipa's response.
    #
    # @return [Haipa::Client::HaipaOperationResponse] Haipa's response.
    def get_operation_response
      haipa_response = HaipaOperationResponse.new(@request, @response, @resource)
      haipa_response
    end

    #
    # Composes and returns cloud error.
    #
    # @return [HaipaOperationError] the cloud error.
    def get_operation_error
      HaipaOperationError.new @request, @response, @error_data, "Long running operation failed with status #{@status}"
    end
    
    def get_request(options = {})
      link = @Haipa_async_operation_header_link || @location_header_link
      options[:connection] = create_connection(options[:base_uri])
      MsRest::HttpOperationRequest.new(nil, link, :get, options)
    end

    private

    # @return [Integer] retry timeout.
    attr_accessor :retry_timeout

    attr_accessor :connection

    def create_connection(base_url)
      @connection ||= Faraday.new(:url => base_url, :ssl => MsRest.ssl_options) do |faraday|
        [[MsRest::RetryPolicyMiddleware, times: 3, retry: 0.02], [:cookie_jar]].each{ |args| faraday.use(*args) }
        faraday.adapter Faraday.default_adapter
        faraday.headers = request.headers
        logging = ENV['HAIPA_HTTP_LOGGING'] || request.log
        if logging
          faraday.response :logger, nil, { :bodies => logging == 'full' }
        end
      end
    end
  end

end
