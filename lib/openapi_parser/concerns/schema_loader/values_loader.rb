# data type values loader
class OpenAPIParser::SchemaLoader::ValuesLoader < OpenAPIParser::SchemaLoader::Base
  # @param [OpenAPIParser::Schemas::Base] target_object
  # @param [Hash] raw_schema
  # @return [Array<OpenAPIParser::Schemas::Base>, nil]
  def load_data(target_object, raw_schema)
    variable_set(target_object, variable_name, raw_schema[schema_key.to_s])
    nil # this loader not return schema object
  end
end
