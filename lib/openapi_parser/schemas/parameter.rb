# TODO: support examples

module OpenAPIParser::Schemas
  class Parameter < Base
    openapi_attr_values :name, :in, :description, :required, :deprecated, :style, :explode, :example

    openapi_attr_value :allow_empty_value, schema_key: :allowEmptyValue
    openapi_attr_value :allow_reserved, schema_key: :allowReserved

    openapi_attr_object :schema, Schema, reference: true
  end
end
