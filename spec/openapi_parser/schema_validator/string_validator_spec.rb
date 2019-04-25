require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::SchemaValidator::StringValidator do
  let(:replace_schema) { {} }
  let(:root) { OpenAPIParser.parse(build_validate_test_schema(replace_schema), config) }
  let(:config) { {} }
  let(:target_schema) do
    root.paths.path['/validate_test'].operation(:post).request_body.content['application/json'].schema
  end
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }

  describe 'validate string pattern' do
    subject { OpenAPIParser::SchemaValidator.validate(params, target_schema, options) }

    let(:params) { {} }
    let(:replace_schema) do
      {
        number_str: {
          type: 'string',
          pattern: '[0-9]+:[0-9]+',
        },
      }
    end

    context 'correct' do
      let(:params) { { 'number_str' => '11:22' } }
      it { expect(subject).to eq({ 'number_str' => '11:22' }) }
    end

    context 'invalid' do
      context 'error pattern' do
        let(:invalid_str) { '11922' }
        let(:params) { { 'number_str' => invalid_str } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e.kind_of?(OpenAPIParser::InvalidPattern)).to eq true
            expect(e.message.start_with?("#{invalid_str} isn't match [0-9]+:[0-9]+ in")).to eq true
          end
        end
      end
    end
  end
end
