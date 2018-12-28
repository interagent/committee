module OpenAPIParser::Parser::Hash
  def _openapi_attr_hash_objects
    @_openapi_attr_hash_objects ||= {}
  end

  def openapi_attr_hash_object(name, klass, options = {})
    target_klass.send(:attr_reader, name)
    _openapi_attr_hash_objects[name] = ::OpenAPIParser::SchemaLoader::HashObjectsLoader.new(name, options.merge(klass: klass))
  end
end
