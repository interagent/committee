require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Operation do
  let(:root) { OpenAPIParser.parse(petstore_schema, {expand_reference: false}) }

  describe "#init" do
    subject{ path_item.get }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }

    it do
      expect(subject).not_to be nil
      expect(subject.object_reference).to eq '#/paths/~1pets/get'
      expect(subject.root.object_id).to be root.object_id
    end
  end

  describe "attributes" do
    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }

    it do
      expect(operation.description.start_with?('Returns all pets')).to eq true
      expect(operation.tags).to eq ['tag_1', 'tag_2']
      expect(operation.summary).to eq 'sum'
      expect(operation.operation_id).to eq 'findPets'
      expect(operation.deprecated).to eq true
      expect(operation.responses.class).to eq OpenAPIParser::Schemas::Responses
      expect(operation._openapi_all_child_objects.size).to eq 5 # parameters * 5 + responses
    end
  end

  describe "parameters" do
    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }

    it do
      expect(operation.parameters.size).to eq 4
      expect(operation.parameters[0].is_a?(OpenAPIParser::Schemas::Parameter)).to eq true
      expect(operation.parameters[2].is_a?(OpenAPIParser::Schemas::Reference)).to eq true
    end
  end

  describe "findable" do
    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }

    it do
      expect(operation.find_object('#/paths/~1pets/get').object_reference).to eq operation.object_reference
      expect(operation.find_object('#/paths/~1pets/get/1')).to eq nil
      expect(operation.find_object('#/paths/~1pets/get/responses').object_reference).to eq operation.responses.object_reference
    end
  end
end
