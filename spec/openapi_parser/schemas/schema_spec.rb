require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Schema do
  let(:root) { OpenAPIParser.parse(petstore_schema, {expand_reference: false}) }

  describe 'correct init' do
    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }

    it do
      parameters = operation.parameters
      s = parameters.first.schema
      # @type OpenAPIParser::Schemas::Schema s

      expect(s).not_to be nil
      expect(s.is_a?(OpenAPIParser::Schemas::Schema)).to eq true
      expect(s.root.object_id).to be root.object_id
      expect(s.object_reference).to eq '#/paths/~1pets/get/parameters/0/schema'
      expect(s.type).to eq 'array'
      expect(s.items.class).to eq OpenAPIParser::Schemas::Schema
      expect(s.additional_properties.class).to eq OpenAPIParser::Schemas::Schema

      s = parameters[1].schema
      expect(s.format).to eq 'int32'
      expect(s.default).to eq 1

      s = parameters[3].schema
      expect(s.all_of.size).to eq 2
      expect(s.all_of[0].class).to eq OpenAPIParser::Schemas::Reference
      expect(s.all_of[1].class).to eq OpenAPIParser::Schemas::Schema

      expect(s.properties.class).to eq Hash
      expect(s.properties['pop'].class).to eq OpenAPIParser::Schemas::Schema
      expect(s.properties['pop'].type).to eq 'string'
      expect(s.properties['pop'].read_only).to eq true
      expect(s.properties['pop'].example).to eq 'test'
      expect(s.properties['pop'].deprecated).to eq true
      expect(s.properties['int'].write_only).to eq true
      expect(s.additional_properties).to eq true
      expect(s.description).to eq 'desc'
      expect(s.nullable).to eq true
    end
  end
end
