require_relative '../spec_helper'

RSpec.describe OpenAPIParser::RequestOperation do
  let(:root) { OpenAPIParser::Schemas::OpenAPI.new(petstore_schema) }
  let(:path_item_finder) { OpenAPIParser::PathItemFinder.new(root.paths) }

  describe 'find' do
    it 'no path items' do
      ro = OpenAPIParser::RequestOperation.create(:get, '/pets', path_item_finder)
      expect(ro.endpoint.object_reference).to eq '#/paths/~1pets/get'
    end

    it 'path items' do
      ro = OpenAPIParser::RequestOperation.create(:get, '/pets/1', path_item_finder)
      expect(ro.endpoint.object_reference).to eq '#/paths/~1pets~1{id}/get'
    end

    it 'no path' do
      ro = OpenAPIParser::RequestOperation.create(:get, 'no', path_item_finder)
      expect(ro).to eq nil
    end

    it 'no method' do
      ro = OpenAPIParser::RequestOperation.create(:head, '/pets/1', path_item_finder)
      expect(ro).to eq nil
    end
  end

  describe 'OpenAPI#request_operation' do
    it 'no path items' do
      ro = root.request_operation(:get, '/pets')
      expect(ro.endpoint.object_reference).to eq '#/paths/~1pets/get'

      ro = OpenAPIParser::RequestOperation.create(:head, '/pets/1', path_item_finder)
      expect(ro).to eq nil
    end
  end
end
