require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Findable do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'openapi object' do
    subject { root }

    it do
      expect(subject.find_object('#/paths/~1pets/get').object_reference).to eq root.paths.path['/pets'].get.object_reference
      expect(subject.find_object('#/components/requestBodies/test_body').object_reference).to eq root.components.request_bodies['test_body'].object_reference

      expect(subject.instance_variable_get(:@find_object_cache).size).to eq 2
    end
  end

  describe 'schema object' do
    subject { root.paths }

    it do
      expect(subject.find_object('#/paths/~1pets/get').object_reference).to eq root.paths.path['/pets'].get.object_reference
    end
  end

  describe 'remote reference' do
    describe 'local file reference' do
      let(:root) { OpenAPIParser.load('spec/data/remote-file-ref.yaml') }
      let(:request_operation) { root.request_operation(:post, '/local_file_reference') }

      it 'validates request body using schema defined in another openapi yaml file' do
        request_operation.validate_request_body('application/json', { 'name' => 'name' })
      end
    end

    describe 'http reference' do
      let(:root) { OpenAPIParser.load('spec/data/remote-http-ref.yaml') }
      let(:request_operation) { root.request_operation(:post, '/http_reference') }

      it 'validates request body using schema defined in openapi yaml file accessed via http' do
        request_operation.validate_request_body('application/json', { 'name' => 'name' })
      end
    end

    describe 'cyclic remote reference' do
      let(:root) { OpenAPIParser.load('spec/data/cyclic-remote-ref1.yaml') }
      let(:request_operation) { root.request_operation(:post, '/cyclic_reference') }

      it 'validates request body using schema defined in another openapi yaml file' do
        request_operation.validate_request_body('application/json', { 'content' => 1 })
      end
    end
  end
end
