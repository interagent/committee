require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Expandable do
  let(:root) { OpenAPIParser.parse(normal_schema, {}) }

  describe 'expand_reference' do
    subject{ root }

    it do
      subject
      expect(subject.find_object('#/paths/~1reference/get/parameters/0').class).to eq OpenAPIParser::Schemas::Parameter
      expect(subject.find_object('#/paths/~1reference/get/responses/default').class).to eq OpenAPIParser::Schemas::Response
      expect(subject.find_object('#/paths/~1reference/post/responses/default').class).to eq OpenAPIParser::Schemas::Response
    end
  end
end
