require 'spec_helper'

RSpec.describe Eryph::Compute::ProblemDetailsError do
  describe '.from_api_error' do
    let(:api_error) do
      double('ApiError',
             code: 400,
             response_body: '{"type":"https://example.com/errors/validation","title":"Validation Error","status":400,"detail":"The request is invalid","instance":"/api/v1/catlets"}',
             message: 'Bad Request')
    end

    it 'creates ProblemDetailsError from API error with JSON response' do
      error = described_class.from_api_error(api_error)

      expect(error).to be_a(described_class)
      expect(error.message).to include('Validation Error')
      expect(error.problem_type).to eq('https://example.com/errors/validation')
      expect(error.title).to eq('Validation Error')
      expect(error.problem_status).to eq(400)
      expect(error.detail).to eq('The request is invalid')
      expect(error.instance).to eq('/api/v1/catlets')
    end

    it 'handles non-JSON response body' do
      api_error_with_text = double('ApiError',
                                   code: 500,
                                   response_body: 'Internal Server Error',
                                   message: 'Internal Server Error')

      error = described_class.from_api_error(api_error_with_text)

      expect(error).to eq(api_error_with_text) # Returns original error when not parseable
    end

    it 'handles missing response body' do
      api_error_no_body = double('ApiError',
                                 code: 404,
                                 response_body: nil,
                                 message: 'Not Found')

      error = described_class.from_api_error(api_error_no_body)

      expect(error).to eq(api_error_no_body) # Returns original error when not parseable
    end
  end

  describe '#initialize' do
    it 'creates error with API error and problem details hash' do
      api_error = double('ApiError', code: 400, message: 'Bad Request')
      problem_details = {
        'type' => 'test-type',
        'title' => 'Test Title',
        'detail' => 'Test detail',
      }

      error = described_class.new(api_error, problem_details)

      expect(error.problem_type).to eq('test-type')
      expect(error.title).to eq('Test Title')
      expect(error.detail).to eq('Test detail')
    end
  end

  describe '#to_s' do
    it 'returns formatted error message' do
      api_error = double('ApiError', code: 400, message: 'Bad Request')
      problem_details = {
        'type' => 'https://example.com/errors/test',
        'title' => 'Test Error',
        'status' => 400,
        'detail' => 'This is a test error',
      }

      error = described_class.new(api_error, problem_details)

      result = error.to_s
      expect(result).to include('Test Error')
      expect(result).to include('This is a test error')
    end
  end

  describe '#problem_details?' do
    it 'returns true when problem details exist' do
      api_error = double('ApiError', message: 'Error')
      error = described_class.new(api_error, { 'title' => 'Test' })

      expect(error.problem_details?).to be true
    end

    it 'returns false when no problem details exist' do
      api_error = double('ApiError', message: 'Error')
      error = described_class.new(api_error)

      expect(error.problem_details?).to be false
    end
  end
end
