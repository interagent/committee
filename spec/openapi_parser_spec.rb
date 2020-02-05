require_relative './spec_helper'
require 'uri'
require 'pathname'

RSpec.describe OpenAPIParser do
  it 'has a version number' do
    expect(OpenAPIParser::VERSION).not_to be nil
  end

  describe 'parse' do
    it do
      parsed = OpenAPIParser.parse(petstore_schema)
      root = OpenAPIParser.parse(petstore_schema, {})
      expect(parsed.openapi).to eq root.openapi
    end
  end

  describe 'load' do
    let(:loaded) { OpenAPIParser.load(petstore_schema_path, {}) }

    it 'loads correct schema' do
      root = OpenAPIParser.parse(petstore_schema, {})
      expect(loaded.openapi).to eq root.openapi
    end

    it 'sets @uri' do
      schema_path = (Pathname.getwd + petstore_schema_path).to_s
      expect(loaded.instance_variable_get(:@uri).to_s).to eq "file://#{schema_path}"
    end
  end

  describe 'load_uri' do
    let(:schema_registry) { {} }
    let(:uri) { URI::File.build(path: (Pathname.getwd + petstore_schema_path).to_s) }
    let!(:loaded) { OpenAPIParser.load_uri(uri, config: OpenAPIParser::Config.new({}), schema_registry: schema_registry) }

    it 'loads correct schema' do
      root = OpenAPIParser.parse(petstore_schema, {})
      expect(loaded.openapi).to eq root.openapi
    end

    it 'sets @uri' do
      expect(loaded.instance_variable_get(:@uri)).to eq uri
    end

    it 'registers schema in schema_registry' do
      expect(schema_registry).to eq({ uri => loaded })
    end
  end
end
