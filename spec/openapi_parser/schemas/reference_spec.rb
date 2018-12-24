require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Reference do
  let(:root) { OpenAPIParser.parse(petstore_schema, { expand_reference: false }) }

  describe 'correct init' do
    subject { operation.parameters[2] }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }

    it do
      expect(subject).not_to be nil
      expect(subject.class).to eq OpenAPIParser::Schemas::Reference
      expect(subject.object_reference).to eq '#/paths/~1pets/get/parameters/2'
      expect(subject.ref).to eq '#/components/parameters/test'
      expect(subject.root.object_id).to be root.object_id
    end
  end
end
