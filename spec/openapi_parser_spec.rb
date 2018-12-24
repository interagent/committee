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
end
