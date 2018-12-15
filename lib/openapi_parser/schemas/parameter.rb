# TODO: support examples

module OpenAPIParser::Schemas
  class Parameter < Base
    openapi_attr_values :name, :in, :description, :required, :deprecated, :style, :explode, :example

    openapi_attr_value :allow_empty_value, schema_key: :allowEmptyValue
    openapi_attr_value :allow_reserved, schema_key: :allowReserved

    # @!attribute [r] schema
    #   @return [Schema, Reference, nil]
    openapi_attr_object :schema, Schema, reference: true

    def in_query?
      self.in == "query"
    end

    def in_path?
      self.in == "path"
    end

    def validate_params(params)
      ::OpenAPIParser::SchemaValidator.validate(params, schema)
    end
  end
end
