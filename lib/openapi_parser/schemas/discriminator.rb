module OpenAPIParser::Schemas
  class Discriminator < Base
    # @!attribute [r] property_name
    #   @return [String, nil]
    openapi_attr_value :property_name, schema_key: :propertyName

    # @!attribute [r] mapping
    #   @return [Hash{String => String]
    openapi_attr_value :mapping
  end
end
