require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Base do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'inspect' do
    subject { root.inspect }

    it { expect(subject).to eq '#' }
  end
end
