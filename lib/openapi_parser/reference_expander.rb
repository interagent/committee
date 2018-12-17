class OpenAPIParser::ReferenceExpander
  class << self
    # @param [OpenAPIParser::Schemas::OpenAPI] openapi
    def expand(openapi)
      openapi.expand_reference(openapi)
      openapi.purge_object_cache
    end
  end
end
