require_relative '../spec_helper'

RSpec.describe OpenAPIParser::ParameterValidator do
  let(:root) { OpenAPIParser::Schemas::OpenAPI.new(normal_schema) }

  describe 'validate' do
    subject { request_operation.validate_request_parameter(params) }

    let(:content_type) { 'application/json' }
    let(:http_method) { :get }
    let(:request_path) { '/validate' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { {} }

    context 'correct' do
      context 'no optional' do
        let(:params) { {"query_string" => "query", "query_integer_list" => [1, 2]} }
        it { expect(subject).to eq nil }
      end

      context 'with optional' do
        let(:params) { {"query_string" => "query", "query_integer_list" => [1, 2], "optional_integer" => 1} }
        it { expect(subject).to eq nil }
      end
    end

    context 'invalid' do
      context 'not exist required' do
        context 'not exist data' do
          let(:params) { {"query_integer_list" => [1, 2]} }

          it do
            expect{ subject }.to raise_error do |e|
              expect(e.is_a?(OpenAPIParser::NotExistRequiredKey)).to eq true
              expect(e.message.start_with?("required parameters query_string not exist")).to eq true
            end
          end
        end

        context 'not exist array' do
          let(:params) { {"query_string" => "query"} }

          it do
            expect{ subject }.to raise_error do |e|
              expect(e.is_a?(OpenAPIParser::NotExistRequiredKey)).to eq true
              expect(e.message.start_with?("required parameters query_integer_list not exist")).to eq true
            end
          end
        end
      end
    end
  end
end
