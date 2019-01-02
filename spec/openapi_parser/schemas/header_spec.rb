require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Header do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'correct init' do
    subject { response.headers['x-next'] }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }
    let(:response) { operation.responses.response['200'] }

    it do
      expect(subject).not_to be nil
      expect(subject.object_reference).to eq '#/paths/~1pets/get/responses/200/headers/x-next'
      expect(subject.root.object_id).to be root.object_id
      expect(subject.schema.class).to be OpenAPIParser::Schemas::Schema
    end
  end
end
