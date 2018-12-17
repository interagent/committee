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

      # TODO: references check
    end
  end
end
