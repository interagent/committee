require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::SchemaValidator::Base do
  describe '#coerce_and_validate(_value, _schema)' do
    subject { OpenAPIParser::SchemaValidator::Base.new(nil, nil).coerce_and_validate(nil, nil) }

    it { expect { subject }.to raise_error(StandardError).with_message('need implement') }
  end
end
