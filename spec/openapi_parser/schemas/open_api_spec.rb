require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::OpenAPI do
  subject { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'init' do
    it 'correct init' do
      expect(subject).not_to be nil
      expect(subject.root.object_id).to eq subject.object_id
    end
  end

  describe '#openapi' do
    it { expect(subject.openapi).to eq '3.0.0' }
  end

  describe '#paths' do
    it { expect(subject.paths).not_to eq nil }
  end

  describe '#components' do
    it { expect(subject.components).not_to eq nil }
  end
end
