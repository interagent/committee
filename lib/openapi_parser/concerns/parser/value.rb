module OpenAPIParser::Parser::Value
  def _openapi_attr_values
    @_openapi_attr_values ||= {}
  end

  def openapi_attr_values(*names)
    names.each { |name| openapi_attr_value(name) }
  end

  def openapi_attr_value(name, options = {})
    target_klass.send(:attr_reader, name)
    _openapi_attr_values[name] = OpenAPIParser::SchemaLoader::ValuesLoader.new(name, options)
  end
end
