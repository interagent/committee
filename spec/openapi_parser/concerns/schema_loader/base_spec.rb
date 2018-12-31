require_relative '../../../spec_helper'

RSpec.describe OpenAPIParser::SchemaLoader::Base do
  describe '#load_data' do
    subject { OpenAPIParser::SchemaLoader::Base.new(nil, {}).load_data(nil, nil) }

    it { expect { subject }.to raise_error(StandardError).with_message('need implement') }
  end
end
