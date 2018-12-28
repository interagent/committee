# Specific Object loader (defined by klass option)
class OpenAPIParser::SchemaLoader::ObjectsLoader < OpenAPIParser::SchemaLoader::Creator
  # @param [OpenAPIParser::Schemas::Base] target_object
  # @param [Hash] raw_schema
  # @return [Array<OpenAPIParser::Schemas::Base>, nil]
  def load_data(target_object, raw_schema)
    obj = create_attr_object(target_object, raw_schema[schema_key.to_s])
    [obj]
  end

  private

    # @return [OpenAPIParser::Schemas::Base]
    def create_attr_object(target_object, schema)
      ref = build_object_reference_from_base(target_object.object_reference, schema_key)

      data = build_openapi_object_from_option(target_object, ref, schema)
      variable_set(target_object, variable_name, data)
      data
    end
end
