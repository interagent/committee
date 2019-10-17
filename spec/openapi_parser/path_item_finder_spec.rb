require_relative '../spec_helper'

RSpec.describe OpenAPIParser::PathItemFinder do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'find' do
    subject { OpenAPIParser::PathItemFinder.new(root.paths) }

    it do
      expect(subject.class).to eq OpenAPIParser::PathItemFinder

      expect(subject.instance_variable_get(:@root).send(:children).size).to eq 1

      result = subject.operation_object(:get, '/pets')
      expect(result.class).to eq OpenAPIParser::PathItemFinder::Result
      expect(result.original_path).to eq('/pets')
      expect(result.operation_object.object_reference).to eq root.find_object('#/paths/~1pets/get').object_reference
      expect(result.path_params.empty?).to eq true

      result = subject.operation_object(:get, '/pets/1')
      expect(result.original_path).to eq('/pets/{id}')
      expect(result.operation_object.object_reference).to eq root.find_object('#/paths/~1pets~1{id}/get').object_reference
      expect(result.path_params['id']).to eq '1'
    end

    it "ignores invalid HTTP methods" do
      expect(subject.operation_object(:exit, '/pets')).to eq(nil)
      expect(subject.operation_object(:blah, '/pets')).to eq(nil)
    end
  end
end
