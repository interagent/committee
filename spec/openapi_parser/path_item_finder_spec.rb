require_relative '../spec_helper'

RSpec.describe OpenAPIParser::PathItemFinder do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'find' do
    subject { OpenAPIParser::PathItemFinder.new(root.paths) }

    it do
      expect(subject.class).to eq OpenAPIParser::PathItemFinder

      expect(subject.instance_variable_get(:@root).send(:children).size).to eq 1

      op, matched_parameters = subject.operation_object(:get, '/pets')
      expect(op.object_reference).to eq root.find_object('#/paths/~1pets/get').object_reference
      expect(matched_parameters.empty?).to eq true

      op, matched_parameters = subject.operation_object(:get, '/pets/1')
      expect(op.object_reference).to eq root.find_object('#/paths/~1pets~1{id}/get').object_reference
      expect(matched_parameters['id']).to eq '1'
    end
  end
end
