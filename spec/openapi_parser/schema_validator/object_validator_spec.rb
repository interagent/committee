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
        expect(e.message).to match("^properties unknown_key are not defined in.*?$")
      end
    end

    it 'throws error when sending multiple unknown property keys with no additionalProperties defined' do
      body = {
        "baskets" => [
          {
            "name"    => "cats",
            "content" => [
              {
                "name"                => "Mr. Cat",
                "born_at"             => "2019-05-16T11:37:02.160Z",
                "description"         => "Cat gentleman",
                "milk_stock"          => 10,
                "unknown_key"         => "value",
                "another_unknown_key" => "another_value"
              }
            ]
          },
        ]
      }

      expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
        expect(e.kind_of?(OpenAPIParser::NotExistPropertyDefinition)).to eq true
        expect(e.message).to match("^properties unknown_key,another_unknown_key are not defined in.*?$")
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

    it 'throws error when sending nil disallowed in allOf' do
      body = {
        "baskets" => [
          {
            "name"    => "turtles",
            "content" => [
              {
                "name"                  => "Mr. Cat",
                "born_at"               => "2019-05-16T11:37:02.160Z",
                "description"           => "Cat gentleman",
                "required_combat_style" => nil,
              }
            ]
          },
        ]
      }

      expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
        expect(e.kind_of?(OpenAPIParser::NotNullError)).to eq true
        expect(e.message).to match("^.*?(don't allow null).*?$")
      end
    end

    it 'passing when sending nil nested to anyOf that is allowed' do
      body = {
        "baskets" => [
          {
            "name"    => "turtles",
            "content" => [
              {
                "name"                  => "Mr. Cat",
                "born_at"               => "2019-05-16T11:37:02.160Z",
                "description"           => "Cat gentleman",
                "optional_combat_style" => nil,
              }
            ]
          },
        ]
      }

      request_operation.validate_request_body(content_type, body)
    end

    it 'throws error when unknown attribute nested in allOf' do
      body = {
        "baskets" => [
          {
            "name"    => "turtles",
            "content" => [
              {
                "name"                  => "Mr. Cat",
                "born_at"               => "2019-05-16T11:37:02.160Z",
                "description"           => "Cat gentleman",
                "required_combat_style" => {
                  "bo_color"              => "brown",
                  "grappling_hook_length" => 10.2
                },
              }
            ]
          },
        ]
      }

      expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
        expect(e.kind_of?(OpenAPIParser::NotAnyOf)).to eq true
        expect(e.message).to match("^.*?(isn't any of).*?$")
      end
    end

    it 'passes error with correct attributes nested in allOf' do
      body = {
        "baskets" => [
          {
            "name"    => "turtles",
            "content" => [
              {
                "name"                  => "Mr. Cat",
                "born_at"               => "2019-05-16T11:37:02.160Z",
                "description"           => "Cat gentleman",
                "required_combat_style" => {
                  "bo_color"       => "brown",
                  "shuriken_count" => 10
                },
              }
            ]
          },
        ]
      }

      request_operation.validate_request_body(content_type, body)
    end

    it 'throws error when unknown attribute nested in allOf' do
      body = {
        "baskets" => [
          {
            "name"    => "turtles",
            "content" => [
              {
                "name"                  => "Mr. Cat",
                "born_at"               => "2019-05-16T11:37:02.160Z",
                "description"           => "Cat gentleman",
                "optional_combat_style" => {
                  "bo_color"              => "brown",
                  "grappling_hook_length" => 10.2
                },
              }
            ]
          },
        ]
      }

      expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
        expect(e.kind_of?(OpenAPIParser::NotAnyOf)).to eq true
        expect(e.message).to match("^.*?(isn't any of).*?$")
      end
    end

    it 'passes error with correct attributes nested in anyOf' do
      body = {
        "baskets" => [
          {
            "name"    => "turtles",
            "content" => [
              {
                "name"                  => "Mr. Cat",
                "born_at"               => "2019-05-16T11:37:02.160Z",
                "description"           => "Cat gentleman",
                "optional_combat_style" => {
                  "bo_color"       => "brown",
                  "shuriken_count" => 10
                },
              }
            ]
          },
        ]
      }

      request_operation.validate_request_body(content_type, body)
    end
  end
end
