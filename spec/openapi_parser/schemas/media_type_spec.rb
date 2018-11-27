require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::MediaType do
  let(:root) { OpenAPIParser::Schemas::OpenAPI.new(petstore_schema) }

  describe 'correct init' do
    subject { request_body.content['application/json'] }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.post }
    let(:request_body) { operation.request_body }

    it do
      expect(subject.class).to eq OpenAPIParser::Schemas::MediaType
      expect(subject.object_reference).to eq '#/paths/~1pets/post/requestBody/content/application~1json'
      expect(subject.root.object_id).to be root.object_id

      expect(subject.schema.class).to eq OpenAPIParser::Schemas::Reference
    end
  end
end
