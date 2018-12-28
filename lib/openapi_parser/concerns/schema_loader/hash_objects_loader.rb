class OpenAPIParser::SchemaLoader::HashObjectsLoader < OpenAPIParser::SchemaLoader::Base
  def create_attr_hash_objects(settings)
    return unless settings

    settings.each do |variable_name, options|
      ref_name_base = options[:schema_key] || variable_name
      klass = options[:klass]
      allow_reference = options[:reference] || false
      allow_data_type = options[:allow_data_type]

      create_attr_hash_object(variable_name, raw_schema[ref_name_base .to_s], ref_name_base, klass, allow_reference, allow_data_type)
    end
  end

  def create_attr_hash_object(variable_name, hash_schema, ref_name_base, klass, allow_reference, allow_data_type) # rubocop:disable Metrics/ParameterLists
    data = if hash_schema
             hash_schema.map { |key, s| [key, build_openapi_object([ref_name_base, key], s, klass, allow_reference, allow_data_type)] }.to_h
           else
             nil
           end

    create_variable(variable_name, data)
    data.values.each { |obj| register_child_to_loader(obj) } if data
  end
end
