require_relative '../spec_helper'

RSpec.describe OpenAPIParser::ParameterValidator do
  let(:root) { OpenAPIParser.parse(normal_schema, config) }
  let(:config) { {} }

  describe 'validate' do
    subject { request_operation.validate_request_parameter(params, {}) }

    let(:content_type) { 'application/json' }
    let(:http_method) { :get }
    let(:request_path) { '/validate' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { {} }

    context 'correct' do
      context 'no optional' do
        let(:params) { { 'query_string' => 'query', 'query_integer_list' => [1, 2], 'queryString' => 'Query' } }
        it { expect(subject).to eq({ 'query_string' => 'query', 'query_integer_list' => [1, 2], 'queryString' => 'Query' }) }
      end

      context 'with optional' do
        let(:params) { { 'query_string' => 'query', 'query_integer_list' => [1, 2], 'queryString' => 'Query', 'optional_integer' => 1 } }
        it { expect(subject).to eq({ 'optional_integer' => 1, 'query_integer_list' => [1, 2], 'queryString' => 'Query', 'query_string' => 'query' }) }
      end
    end

    context 'invalid' do
      context 'not exist required' do
        context 'not exist data' do
          let(:params) { { 'query_integer_list' => [1, 2], 'queryString' => 'Query' } }

          it do
            expect { subject }.to raise_error do |e|
              expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
              expect(e.message).to end_with('missing required parameters: query_string')
            end
          end
        end

        context 'not exist array' do
          let(:params) { { 'query_string' => 'query', 'queryString' => 'Query' } }

          it do
            expect { subject }.to raise_error do |e|
              expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
              expect(e.message).to end_with('missing required parameters: query_integer_list')
            end
          end
        end
      end

      context 'non null check' do
        context 'optional' do
          let(:params) { { 'query_string' => 'query', 'query_integer_list' => [1, 2], 'queryString' => 'Query', 'optional_integer' => nil } }
          it { expect { subject }.to raise_error(OpenAPIParser::NotNullError) }
        end

        context 'optional' do
          let(:params) { { 'query_string' => 'query', 'query_integer_list' => nil, 'queryString' => 'Query' } }
          it { expect { subject }.to raise_error(OpenAPIParser::NotNullError) }
        end
      end
    end
  end
end
