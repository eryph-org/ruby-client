require 'json'

module Eryph
  module Compute
    # Exception class for API errors that include ProblemDetails in the response
    # Extends StandardError with parsed problem details information
    class ProblemDetailsError < StandardError
      attr_reader :problem_details, :problem_type, :title, :detail, :instance, :problem_status
      attr_reader :code, :response_headers, :response_body
      
      # Create a new ProblemDetailsError
      # @param api_error [Object] the original API error (could be ComputeClient::ApiError or similar)
      # @param problem_details [Object, Hash] the parsed problem details
      def initialize(api_error, problem_details = nil)
        # Extract basic error information
        @code = api_error.respond_to?(:code) ? api_error.code : nil
        @response_headers = api_error.respond_to?(:response_headers) ? api_error.response_headers : nil
        @response_body = api_error.respond_to?(:response_body) ? api_error.response_body : nil
        
        # Initialize with the original error's message or a default
        original_message = api_error.respond_to?(:message) ? api_error.message : api_error.to_s
        super(original_message)
        
        @problem_details = problem_details
        
        if problem_details
          if problem_details.respond_to?(:type)
            # ComputeClient::ProblemDetails object
            @problem_type = problem_details.type
            @title = problem_details.title
            @detail = problem_details.detail
            @instance = problem_details.instance
            @problem_status = problem_details.status
          elsif problem_details.is_a?(Hash)
            # Hash representation
            @problem_type = problem_details[:type] || problem_details['type']
            @title = problem_details[:title] || problem_details['title']
            @detail = problem_details[:detail] || problem_details['detail']
            @instance = problem_details[:instance] || problem_details['instance']
            @problem_status = problem_details[:status] || problem_details['status']
          end
        end
      end
      
      # Create a ProblemDetailsError from an ApiError by parsing the response body
      # @param api_error [Object] the original API error
      # @return [ProblemDetailsError, Object] parsed error or original if not parseable
      def self.from_api_error(api_error)
        response_body = api_error.respond_to?(:response_body) ? api_error.response_body : nil
        problem_details = parse_problem_details(response_body)
        
        if problem_details
          new(api_error, problem_details)
        else
          api_error
        end
      end
      
      # Parse ProblemDetails from a response body
      # @param response_body [String] the HTTP response body
      # @return [Object, Hash, nil] parsed problem details or nil if not parseable
      def self.parse_problem_details(response_body)
        return nil if response_body.nil? || response_body.empty?
        
        begin
          json_data = JSON.parse(response_body)
          
          # Check if it looks like a problem details response
          if json_data.is_a?(Hash) && (json_data.key?('type') || json_data.key?('title'))
            # Try to create a proper ProblemDetails object if the class is available
            begin
              if defined?(ComputeClient::ProblemDetails)
                ComputeClient::ProblemDetails.build_from_hash(json_data)
              else
                # Fall back to hash representation if class not available
                json_data
              end
            rescue
              # Fall back to hash representation if object creation fails
              json_data
            end
          else
            nil
          end
        rescue JSON::ParserError
          nil
        end
      end
      
      # Check if this error has problem details information
      # @return [Boolean] true if problem details are available
      def has_problem_details?
        !@problem_details.nil?
      end
      
      # Get a user-friendly error message
      # @return [String] formatted error message
      def friendly_message
        if has_problem_details?
          parts = []
          parts << @title if @title && !@title.empty?
          parts << @detail if @detail && !@detail.empty?
          
          if parts.empty?
            "API Error: #{@problem_type || 'Unknown error'}"
          else
            parts.join(': ')
          end
        else
          super.message
        end
      end
      
      # Override message to provide better error information
      def message
        if has_problem_details?
          msg = friendly_message
          msg += "\nProblem Type: #{@problem_type}" if @problem_type
          msg += "\nInstance: #{@instance}" if @instance
          msg += "\nHTTP Status: #{code}" if code
          msg
        else
          super
        end
      end
      
      # String representation
      def to_s
        friendly_message
      end
      
      def inspect
        if has_problem_details?
          "#<ProblemDetailsError problem_type=#{@problem_type.inspect} title=#{@title.inspect} status=#{code}>"
        else
          super
        end
      end
    end
  end
end