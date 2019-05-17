require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::RequestBody do
  let(:root) { OpenAPIParser.parse(petstore_with_discriminator_schema, {}) }

  describe 'object properties' do
    let(:content_type) { 'application/json' }
    let(:http_method) { :post }
    let(:request_path) { '/save_the_pets' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { {} }

    it 'throws error when sending unknown property key with no additionalProperties defined' do
      body = {
        "baskets" => [
          {
            "name"    => "cats",
            "content" => [
              {
                "name"        => "Mr. Cat",
                "born_at"     => "2019-05-16T11:37:02.160Z",
                "description" => "Cat gentleman",
                "milk_stock"  => 10,
                "unknown_key" => "value"
              }
            ]
          },
        ]
      }

      expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
        expect(e.kind_of?(OpenAPIParser::NotExistPropertyDefinition)).to eq true
        expect(e.message).to match("^property unknown_key is not defined in.*?$")
      end
    end

    it 'ignores unknown property key if additionalProperties is defined' do
      # TODO: we have to use additional properties to do the validation
      body = {
        "baskets" => [
          {
            "name"    => "squirrels",
            "content" => [
              {
                "name"        => "Mrs. Squirrel",
                "born_at"     => "2019-05-16T11:37:02.160Z",
                "description" => "Squirrel superhero",
                "nut_stock"   => 10,
                "unknown_key" => "value"
              }
            ]
          },
        ]
      }

      request_operation.validate_request_body(content_type, body)
    end
  end
end
