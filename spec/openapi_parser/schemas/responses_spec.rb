require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Responses do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'correct init' do
    subject { operation.responses }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }

    it do
      expect(subject.class).to eq OpenAPIParser::Schemas::Responses
      expect(subject.root.object_id).to be root.object_id

      expect(subject.object_reference).to eq '#/paths/~1pets/get/responses'
      expect(subject.default.class).to eq OpenAPIParser::Schemas::Response
      expect(subject.response['200'].class).to eq OpenAPIParser::Schemas::Response

      expect(subject.response['200'].object_reference).to eq '#/paths/~1pets/get/responses/200'
    end
  end

  describe '#validate_response_body(status_code, content_type, params)' do
    subject { responses.validate_response_body(status_code, content_type, params, response_validate_options) }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }
    let(:responses) { operation.responses }
    let(:content_type) { 'application/json' }
    let(:response_validate_options) { OpenAPIParser::SchemaValidator::ResponseValidateOptions.new }

    context '200' do
      let(:params) { [{ 'id' => 1, 'name' => 'name' }] }
      let(:status_code) { 200 }

      it { expect(subject).to eq([{ 'id' => 1, 'name' => 'name' }]) }
    end

    context '4XX' do
      let(:status_code) { 400 }

      context 'correct' do
        let(:params) { { 'message' => 'error' } }

        it { expect(subject).to eq({ 'message' => 'error' }) }
      end

      context 'invalid (200 response)' do
        let(:params) { [{ 'id' => 1, 'name' => 'name' }] }

        it { expect { subject }.to raise_error(OpenAPIParser::ValidateError) }
      end
    end

    context '404 (prefer use 4xx)' do
      let(:status_code) { 404 }

      context 'correct' do
        let(:params) { { 'id' => 1 } }

        it { expect(subject).to eq({ 'id' => 1 }) }
      end

      context 'invalid (4xx response)' do
        let(:params) { { 'message' => 'error' } }

        it { expect { subject }.to raise_error(OpenAPIParser::NotExistRequiredKey) }
      end
    end

    context 'invalid status code use default' do
      context 'bigger' do
        let(:status_code) { 1400 }
        let(:params) { { 'message' => 'error' } }

        it { expect { subject }.to raise_error(OpenAPIParser::NotExistRequiredKey) }
      end

      context 'smaller' do
        let(:status_code) { 40 }

        let(:params) { { 'message' => 'error' } }

        it { expect { subject }.to raise_error(OpenAPIParser::NotExistRequiredKey) }
      end
    end
  end
end
