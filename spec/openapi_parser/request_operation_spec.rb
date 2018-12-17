require_relative '../spec_helper'

RSpec.describe OpenAPIParser::RequestOperation do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }
  let(:config) { OpenAPIParser::Config.new({}) }
  let(:path_item_finder) { OpenAPIParser::PathItemFinder.new(root.paths) }

  describe 'find' do
    it 'no path items' do
      ro = OpenAPIParser::RequestOperation.create(:get, '/pets', path_item_finder, config.request_validator_options)
      expect(ro.operation_object.object_reference).to eq '#/paths/~1pets/get'
    end

    it 'path items' do
      ro = OpenAPIParser::RequestOperation.create(:get, '/pets/1', path_item_finder, config.request_validator_options)
      expect(ro.operation_object.object_reference).to eq '#/paths/~1pets~1{id}/get'
    end

    it 'no path' do
      ro = OpenAPIParser::RequestOperation.create(:get, 'no', path_item_finder, config.request_validator_options)
      expect(ro).to eq nil
    end

    it 'no method' do
      ro = OpenAPIParser::RequestOperation.create(:head, '/pets/1', path_item_finder, config.request_validator_options)
      expect(ro).to eq nil
    end
  end

  describe 'OpenAPI#request_operation' do
    it 'no path items' do
      ro = root.request_operation(:get, '/pets')
      expect(ro.operation_object.object_reference).to eq '#/paths/~1pets/get'

      ro = OpenAPIParser::RequestOperation.create(:head, '/pets/1', path_item_finder, config.request_validator_options)
      expect(ro).to eq nil
    end
  end

  describe 'validate_response_body' do
    subject { request_operation.validate_response_body(status_code, content_type, data, options) }

    let(:options) { OpenAPIParser::SchemaValidator::Options.new(coerce_value: false)}

    let(:status_code) { 200 }
    let(:root) { OpenAPIParser.parse(normal_schema, {}) }
    let(:request_operation) { root.request_operation(:post, '/validate')}
    let(:content_type) { 'application/json' }

    context 'correct' do
      let(:data) { {"string" => "Honoka.Kousaka"} }

      it { expect(subject).to eq({"string"=>"Honoka.Kousaka"}) }
    end

    context 'no content type' do
      let(:content_type) { nil }
      let(:data) { {"string" => 1} }

      it { expect(subject).to eq nil }
    end

    context 'invalid schema' do
      let(:data) { {"string" => 1} }

      it do
        expect{ subject }.to raise_error do |e|
          expect(e.is_a?(OpenAPIParser::ValidateError)).to eq true
          expect(e.message.start_with?("1 class is Integer")).to eq true
        end
      end
    end

    context 'no status code use default' do
      let(:status_code) { 419 }
      let(:data) { {"integer" => '1'} }

      it do
        expect{ subject }.to raise_error do |e|
          expect(e.is_a?(OpenAPIParser::ValidateError)).to eq true
          expect(e.message.start_with?("1 class is String")).to eq true
        end
      end
    end
  end
end
