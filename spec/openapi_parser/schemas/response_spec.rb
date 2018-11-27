require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Response do
  let(:root) { OpenAPIParser::Schemas::OpenAPI.new(petstore_schema) }

  describe 'correct init' do
    subject { responses.default }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }
    let(:responses) { operation.responses }

    it do
      expect(subject.class).to eq OpenAPIParser::Schemas::Response
      expect(subject.object_reference).to eq '#/paths/~1pets/get/responses/default'
      expect(subject.root.object_id).to be root.object_id

      expect(subject.description).to eq 'unexpected error'
      expect(subject.content.class).to eq Hash

      expect(subject.content['application/json'].class).to eq OpenAPIParser::Schemas::MediaType
      expect(subject.content['application/json'].object_reference).to eq '#/paths/~1pets/get/responses/default/content/application~1json'
    end
  end
end
