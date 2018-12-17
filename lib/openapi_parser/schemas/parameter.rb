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

    # @return [Object] coerced or original params
    # @param [OpenAPIParser::SchemaValidator::Options] options
    def validate_params(params, options)
      ::OpenAPIParser::SchemaValidator.validate(params, schema, options)
    end
  end
end
