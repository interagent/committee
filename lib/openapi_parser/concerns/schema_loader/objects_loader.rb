class OpenAPIParser::SchemaLoader::ObjectsLoader < OpenAPIParser::SchemaLoader::Base
  def create_attr_objects(values)
    return unless values

    values.each do |name, options|
      key = options[:schema_key] || name
      klass = options[:klass]
      allow_reference = options[:reference] || false
      allow_data_type = options[:allow_data_type]

      obj = create_attr_object(name, key, raw_schema[key.to_s], klass, allow_reference, allow_data_type)
      register_child_to_loader(obj)
    end
  end

  # @return [OpenAPIParser::Schemas::Base]
  def create_attr_object(variable_name, ref_name, schema, klass, allow_reference, allow_data_type) # rubocop:disable Metrics/ParameterLists
    data = build_openapi_object(ref_name, schema, klass, allow_reference, allow_data_type)
    create_variable(variable_name, data)
    data
  end
end
