class OpenAPIParser::SchemaLoader::ValuesLoader < OpenAPIParser::SchemaLoader::Base
  def create_attr_values(values)
    return unless values

    values.each do |variable_name, options|
      key = options[:schema_key] || variable_name

      create_variable(variable_name, raw_schema[key.to_s])
    end
  end
end
