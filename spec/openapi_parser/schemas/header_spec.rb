require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Header do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'correct init' do
    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }
    let(:response) { operation.responses.response['200'] }

    it do
      h = response.headers['x-next']

      expect(h).not_to be nil
      expect(h.object_reference).to eq '#/paths/~1pets/get/responses/200/headers/x-next'
      expect(h.root.object_id).to be root.object_id
      expect(h.schema.class).to be OpenAPIParser::Schemas::Schema
    end

    it 'headers reference' do
      h = response.headers['x-limit']

      expect(h).not_to be nil
      expect(h.class).to be OpenAPIParser::Schemas::Header
      expect(h.object_reference).to eq '#/components/headers/X-Rate-Limit-Limit'
    end
  end
end
