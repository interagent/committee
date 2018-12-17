require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Findable do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'openapi object' do
    subject{ root }

    it do
      expect(subject.find_object('#/paths/~1pets/get').object_reference).to eq root.paths.path['/pets'].get.object_reference
      expect(subject.find_object('#/components/requestBodies/test_body').object_reference).to eq root.components.request_bodies['test_body'].object_reference

      expect(subject.instance_variable_get(:@find_object_cache).size).to eq 2
    end
  end

  describe 'schema object' do
    subject{ root.paths }

    it do
      expect(subject.find_object('#/paths/~1pets/get').object_reference).to eq root.paths.path['/pets'].get.object_reference
    end
  end
end
