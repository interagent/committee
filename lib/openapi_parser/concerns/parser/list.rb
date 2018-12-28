module OpenAPIParser::Parser::List
  def _openapi_attr_list_objects
    @_openapi_attr_list_objects ||= {}
  end

  def openapi_attr_list_object(name, klass, options = {})
    target_klass.send(:attr_reader, name)
    _openapi_attr_list_objects[name] = OpenAPIParser::SchemaLoader::ListLoader.new(name, options.merge(klass: klass))
  end
end
