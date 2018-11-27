module OpenAPIParser::Schemas
  class Reference < Base
    openapi_attr_value :ref, schema_key: '$ref'
  end
end
