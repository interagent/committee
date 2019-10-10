require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::SchemaValidator::IntegerValidator do
  let(:replace_schema) { {} }
  let(:root) { OpenAPIParser.parse(build_validate_test_schema(replace_schema), config) }
  let(:config) { {} }
  let(:target_schema) do
    root.paths.path['/validate_test'].operation(:post).request_body.content['application/json'].schema
  end
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }

  describe 'validate integer maximum value' do
    subject { OpenAPIParser::SchemaValidator.validate(params, target_schema, options) }

    let(:params) { {} }
    let(:replace_schema) do
      {
        my_integer: {
          type: 'integer',
          maximum: 10,
        },
      }
    end

    context 'correct' do
      let(:params) { { 'my_integer' => 10 } }
      it { expect(subject).to eq({ 'my_integer' => 10 }) }
    end

    context 'invalid' do
      context 'more than maximum' do
        let(:more_than_maximum) { 11 }
        let(:params) { { 'my_integer' => more_than_maximum } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::MoreThanMaximum)
            expect(e.message).to end_with("#{more_than_maximum} is more than maximum value")
          end
        end
      end
    end
  end

  describe 'validate integer minimum value' do
    subject { OpenAPIParser::SchemaValidator.validate(params, target_schema, options) }

    let(:params) { {} }
    let(:replace_schema) do
      {
        my_integer: {
          type: 'integer',
          minimum: 10,
        },
      }
    end

    context 'correct' do
      let(:params) { { 'my_integer' => 10 } }
      it { expect(subject).to eq({ 'my_integer' => 10 }) }
    end

    context 'invalid' do
      context 'less than minimum' do
        let(:less_than_minimum) { 9 }
        let(:params) { { 'my_integer' => less_than_minimum } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::LessThanMinimum)
            expect(e.message).to end_with("#{less_than_minimum} is less than minimum value")
          end
        end
      end
    end
  end

  describe 'validate integer exclusiveMaximum value' do
    subject { OpenAPIParser::SchemaValidator.validate(params, target_schema, options) }

    let(:params) { {} }
    let(:replace_schema) do
      {
        my_integer: {
          type: 'integer',
          maximum: 10,
          exclusiveMaximum: true,
        },
      }
    end

    context 'correct' do
      let(:params) { { 'my_integer' => 9 } }
      it { expect(subject).to eq({ 'my_integer' => 9 }) }
    end

    context 'invalid' do
      context 'more than or equal to exclusive maximum' do
        let(:more_than_equal_exclusive_maximum) { 10 }
        let(:params) { { 'my_integer' => more_than_equal_exclusive_maximum } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e.kind_of?(OpenAPIParser::MoreThanExclusiveMaximum)).to eq true
            expect(e.message.start_with?("#{more_than_equal_exclusive_maximum} cannot be more than or equal to exclusive maximum")).to eq true
          end
        end
      end
    end
  end

  describe 'validate integer exclusiveMinimum value' do
    subject { OpenAPIParser::SchemaValidator.validate(params, target_schema, options) }

    let(:params) { {} }
    let(:replace_schema) do
      {
        my_integer: {
          type: 'integer',
          minimum: 10,
          exclusiveMinimum: true,
        },
      }
    end

    context 'correct' do
      let(:params) { { 'my_integer' => 11 } }
      it { expect(subject).to eq({ 'my_integer' => 11 }) }
    end

    context 'invalid' do
      context 'less than or equal to exclusive minimum' do
        let(:less_than_equal_exclusive_minimum) { 10 }
        let(:params) { { 'my_integer' => less_than_equal_exclusive_minimum } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::LessThanExclusiveMinimum)
            expect(e.message).to end_with("#{less_than_equal_exclusive_minimum} cannot be less than or equal to exclusive minimum value")
          end
        end
      end
    end
  end
end
