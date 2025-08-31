require 'spec_helper'

RSpec.describe Eryph::Compute do
  describe 'module structure' do
    it 'defines expected error classes' do
      expect(described_class::ComputeError).to be_a(Class)
      expect(described_class::ComputeError.superclass).to eq(StandardError)
    end
    
    it 'defines ApiError' do
      expect(described_class::ApiError).to be_a(Class)
      expect(described_class::ApiError.superclass).to eq(described_class::ComputeError)
    end
  end
  
  describe '.version' do
    it 'returns version string' do
      expect(Eryph::Compute::VERSION).to be_a(String)
      expect(Eryph::Compute::VERSION).to match(/\d+\.\d+\.\d+/)
    end
  end
  
  describe 'ApiError' do
    let(:error_message) { 'API request failed' }
    let(:error_code) { 400 }
    let(:response_body) { '{"error": "Bad Request"}' }
    let(:response_headers) { { 'Content-Type' => 'application/json' } }
    
    it 'initializes with message and attributes' do
      error = described_class::ApiError.new(error_message, code: error_code, response_body: response_body, response_headers: response_headers)
      
      expect(error.message).to eq(error_message)
      expect(error.code).to eq(error_code)
      expect(error.response_body).to eq(response_body)
      expect(error.response_headers).to eq(response_headers)
    end
    
    it 'inherits from ComputeError' do
      error = described_class::ApiError.new(error_message)
      expect(error).to be_a(described_class::ComputeError)
    end
    
    it 'can be created with only message' do
      error = described_class::ApiError.new(error_message)
      expect(error.message).to eq(error_message)
      expect(error.code).to be_nil
      expect(error.response_body).to be_nil
      expect(error.response_headers).to be_nil
    end
  end
end