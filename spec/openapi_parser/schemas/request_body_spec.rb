require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::RequestBody do
  let(:root) { OpenAPIParser::Schemas::OpenAPI.new(petstore_schema) }

  describe 'correct init' do
    subject { operation.request_body }
    
    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.post }

    it do
      expect(subject).not_to be nil
      expect(subject.object_reference).to eq '#/paths/~1pets/post/requestBody'
      expect(subject.description).to eq 'Pet to add to the store'
      expect(subject.required).to eq true
      expect(subject.content.class).to eq Hash
      expect(subject.root.object_id).to be root.object_id
    end
  end
end
