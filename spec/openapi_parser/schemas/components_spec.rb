require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Components do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'correct init' do
    subject { root.find_object('#/components') }

    it do
      expect(subject.root.object_id).to be root.object_id
      expect(subject.class).to eq OpenAPIParser::Schemas::Components
      expect(subject.object_reference).to eq '#/components'

      expect(subject.parameters['test'].class).to eq OpenAPIParser::Schemas::Parameter
      expect(subject.parameters['test_ref'].class).to eq OpenAPIParser::Schemas::Parameter

      expect(subject.schemas['Pet'].class).to eq OpenAPIParser::Schemas::Schema

      expect(subject.responses['normal'].class).to eq OpenAPIParser::Schemas::Response

      expect(subject.request_bodies['test_body'].class).to eq OpenAPIParser::Schemas::RequestBody
      expect(subject.request_bodies['test_body'].object_reference).to eq '#/components/requestBodies/test_body'
    end
  end
end
