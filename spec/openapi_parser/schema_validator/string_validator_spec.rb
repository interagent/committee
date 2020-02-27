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
      let(:invalid_str) { '11922' }
      let(:params) { { 'number_str' => invalid_str } }

      context 'error pattern' do
        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::InvalidPattern)
            expect(e.message).to end_with("pattern [0-9]+:[0-9]+ does not match value: #{invalid_str}")
          end
        end
      end

      context 'error pattern with example' do
        let(:replace_schema) do
          {
            number_str: {
              type: 'string',
              pattern: '[0-9]+:[0-9]+',
              example: '11:22'
            },
          }
        end

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::InvalidPattern)
            expect(e.message).to end_with("pattern [0-9]+:[0-9]+ does not match value: #{invalid_str}, example: 11:22")
          end
        end
      end
    end
  end

  describe 'validate string length' do
    subject { OpenAPIParser::SchemaValidator.validate(params, target_schema, options) }

    describe 'validate max length' do
      let(:params) { {} }
      let(:replace_schema) do
        {
          str: {
            type: 'string',
            maxLength: 5,
          },
        }
      end

      context 'valid' do
        let(:value) { 'A' * 5 }
        let(:params) { { 'str' => value } }
        it { is_expected.to eq({ 'str' => value }) }
      end

      context 'invalid' do
        context 'more than max' do
          let(:value) { 'A' * 6 }
          let(:params) { { 'str' => value } }

          it do
            expect { subject }.to raise_error do |e|
              expect(e).to be_kind_of(OpenAPIParser::MoreThanMaxLength)
              expect(e.message).to end_with("#{value} is longer than max length")
            end
          end
        end
      end
    end

    describe 'validate min length' do
      let(:params) { {} }
      let(:replace_schema) do
        {
          str: {
            type: 'string',
            minLength: 5,
          },
        }
      end

      context 'valid' do
        let(:value) { 'A' * 5 }
        let(:params) { { 'str' => value } }
        it { is_expected.to eq({ 'str' => value }) }
      end

      context 'invalid' do
        context 'less than min' do
          let(:value) { 'A' * 4 }
          let(:params) { { 'str' => value } }

          it do
            expect { subject }.to raise_error do |e|
              expect(e).to be_kind_of(OpenAPIParser::LessThanMinLength)
              expect(e.message).to end_with("#{value} is shorter than min length")
            end
          end
        end
      end
    end
  end

  describe 'validate email format' do
    subject { OpenAPIParser::SchemaValidator.validate(params, target_schema, options) }

    let(:params) { {} }
    let(:replace_schema) do
      {
        email_str: {
          type: 'string',
          format: 'email',
        },
      }
    end

    context 'correct' do
      let(:params) { { 'email_str' => 'hello@example.com' } }
      it { expect(subject).to eq({ 'email_str' => 'hello@example.com' }) }
    end

    context 'invalid' do
      context 'error pattern' do
        let(:value) { 'not_email' }
        let(:params) { { 'email_str' => value } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::InvalidEmailFormat)
            expect(e.message).to end_with("email address format does not match value: not_email")
          end
        end
      end
    end
  end

  describe 'validate uuid format' do
    subject { OpenAPIParser::SchemaValidator.validate(params, target_schema, options) }

    let(:params) { {} }
    let(:replace_schema) do
      {
        uuid_str: {
          type: 'string',
          format: 'uuid',
        },
      }
    end

    context 'correct' do
      let(:params) { { 'uuid_str' => 'fd33fb1e-b1f6-401e-994d-8a2545e1aef7' } }
      it { expect(subject).to eq({ 'uuid_str' => 'fd33fb1e-b1f6-401e-994d-8a2545e1aef7' }) }
    end

    context 'invalid' do
      context 'error pattern' do
        let(:value) { 'not_uuid' }
        let(:params) { { 'uuid_str' => value } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::InvalidUUIDFormat)
            expect(e.message).to end_with("Value: not_uuid is not conformant with UUID format")
          end
        end
      end
    end
  end
end
