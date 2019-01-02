require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Parameter do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'correct init' do
    subject { operation.parameters.first }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }

    it do
      expect(subject).not_to be nil
      expect(subject.object_reference).to eq '#/paths/~1pets/get/parameters/0'
      expect(subject.root.object_id).to be root.object_id
    end
  end

  describe 'attributes' do
    subject { operation.parameters.first }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }

    it do
      results = {
        name: 'tags',
        in: 'query',
        description: 'tags to filter by',
        required: false,
        style: 'form',
      }

      results.each { |k, v| expect(subject.send(k)).to eq v }

      expect(subject.allow_empty_value).to eq true
    end
  end

  describe 'header support' do
    subject { path_item.parameters.last }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/animals/{id}'] }

    it do
      results = {
        name: 'token',
        in: 'header',
        description: 'token to be passed as a header',
        required: true,
        style: 'simple',
      }

      results.each { |k, v| expect(subject.send(k)).to eq v }

      expect(subject.schema.type).to eq 'integer'
    end
  end
end
