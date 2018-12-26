class OpenAPIParser::SchemaLoader::HashBodyLoader < OpenAPIParser::SchemaLoader::Base
  def create_attr_hash_body_objects(values)
    return unless values

    values.each do |name, options|
      klass = options[:klass]
      allow_reference = options[:reference] || false
      allow_data_type = options[:allow_data_type]
      reject_keys = options[:reject_keys]

      create_hash_body_objects(name, raw_schema, klass, allow_reference, allow_data_type, reject_keys)
    end
  end

  # for responses and paths object
  def create_hash_body_objects(name, schema, klass, allow_reference, allow_data_type, reject_keys) # rubocop:disable Metrics/ParameterLists
    unless schema
      create_variable(name, nil)
      return
    end

    object_list = schema.reject { |k, _| reject_keys.include?(k) }.map do |child_name, child_schema|
      [
        child_name.to_s, # support string key only in OpenAPI3
        build_openapi_object(escape_reference(child_name), child_schema, klass, allow_reference, allow_data_type),
      ]
    end

    objects = object_list.to_h
    create_variable(name, objects)
    objects.values.each { |o| register_child_to_loader(o) }
  end
end
