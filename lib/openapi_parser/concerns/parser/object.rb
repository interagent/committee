module OpenAPIParser::Parser::Object
  def _openapi_attr_objects
    @_openapi_attr_objects ||= {}
  end

  def openapi_attr_objects(*names, klass)
    names.each { |name| openapi_attr_object(name, klass) }
  end

  def openapi_attr_object(name, klass, options = {})
    target_klass.send(:attr_reader, name)
    _openapi_attr_objects[name] = OpenAPIParser::SchemaLoader::ObjectsLoader.new(name, options.merge(klass: klass))
  end
end
