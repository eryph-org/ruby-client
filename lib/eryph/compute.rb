# Eryph Compute Client
# High-level client for the Eryph Compute API

require_relative 'compute/version'
require_relative 'compute/client'

module Eryph
  # Compute API client module
  module Compute
    # Error raised when compute API operations fail
    class ComputeError < StandardError; end

    # Error raised when API responses are invalid
    class ApiError < ComputeError
      # @return [Integer] HTTP response code
      attr_reader :code

      # @return [String] response body
      attr_reader :response_body

      # @return [Hash] response headers
      attr_reader :response_headers

      # Initialize API error
      # @param message [String] error message
      # @param code [Integer] HTTP response code
      # @param response_body [String] response body
      # @param response_headers [Hash] response headers
      def initialize(message, code: nil, response_body: nil, response_headers: nil)
        super(message)
        @code = code
        @response_body = response_body
        @response_headers = response_headers
      end
    end
  end
end