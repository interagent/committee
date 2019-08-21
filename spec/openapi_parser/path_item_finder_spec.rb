require_relative '../spec_helper'

RSpec.describe OpenAPIParser::PathItemFinder do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'find' do
    subject { OpenAPIParser::PathItemFinder.new(root.paths) }

    it do
      expect(subject.class).to eq OpenAPIParser::PathItemFinder

      result = subject.operation_object(:get, '/pets')
      expect(result.class).to eq OpenAPIParser::PathItemFinder::Result
      expect(result.original_path).to eq('/pets')
      expect(result.operation_object.object_reference).to eq root.find_object('#/paths/~1pets/get').object_reference
      expect(result.path_params.empty?).to eq true

      result = subject.operation_object(:get, '/pets/1')
      expect(result.original_path).to eq('/pets/{id}')
      expect(result.operation_object.object_reference).to eq root.find_object('#/paths/~1pets~1{id}/get').object_reference
      expect(result.path_params['id']).to eq '1'

      result = subject.operation_object(:post, '/pets/lessie/adopt/123')
      expect(result.original_path).to eq('/pets/{nickname}/adopt/{param_2}')
      expect(result.operation_object.object_reference)
        .to eq root.find_object('#/paths/~1pets~1{nickname}~1adopt~1{param_2}/post').object_reference
      expect(result.path_params['nickname']).to eq 'lessie'
      expect(result.path_params['param_2']).to eq '123'
    end
  end
end
