class OpenAPIParser::SchemaLoader::ListLoader < OpenAPIParser::SchemaLoader::Base
  def create_attr_list_objects(settings)
    return unless settings

    settings.each do |variable_name, options|
      ref_name_base = options[:schema_key] || variable_name
      klass = options[:klass]
      allow_reference = options[:reference] || false
      allow_data_type = options[:allow_data_type]

      create_attr_list_object(variable_name, raw_schema[ref_name_base.to_s], ref_name_base, klass, allow_reference, allow_data_type)
    end
  end

  def create_attr_list_object(variable_name, array_schema, ref_name_base, klass, allow_reference, allow_data_type) # rubocop:disable Metrics/ParameterLists
    data = if array_schema
             array_schema.map.with_index { |s, idx| build_openapi_object([ref_name_base, idx], s, klass, allow_reference, allow_data_type) }
           else
             nil
           end

    create_variable(variable_name, data)
    data.each { |obj| register_child_to_loader(obj) } if data
  end
end
