module OpenAPIParser::Parser::HashBody
  def _openapi_attr_hash_body_objects
    @_openapi_attr_hash_body_objects ||= {}
  end

  def openapi_attr_hash_body_objects(name, klass, options = {})
    # options[:reject_keys] = options[:reject_keys] ? options[:reject_keys].map(&:to_s) : []

    target_klass.send(:attr_reader, name)
    _openapi_attr_hash_body_objects[name] = ::OpenAPIParser::SchemaLoader::HashBodyLoader.new(name, options.merge(klass: klass))
  end
end
