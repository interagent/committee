# TODO: info object
# TODO: servers object
# TODO: tags object
# TODO: externalDocs object

module OpenAPIParser::Schemas
  class OpenAPI < Base
    def initialize(raw_schema, config, uri: nil, schema_registry: {})
      super('#', nil, self, raw_schema)
      @find_object_cache = {}
      @path_item_finder = OpenAPIParser::PathItemFinder.new(paths) if paths # invalid definition
      @config = config
      @uri = uri
      @schema_registry = schema_registry

      # schema_registery is shared among schemas, and prevents a schema from being loaded multiple times
      schema_registry[uri] = self if uri
    end

    # @!attribute [r] openapi
    #   @return [String, nil]
    openapi_attr_values :openapi

    # @!attribute [r] paths
    #   @return [Paths, nil]
    openapi_attr_object :paths, Paths, reference: false

    # @!attribute [r] components
    #   @return [Components, nil]
    openapi_attr_object :components, Components, reference: false

    # @return [OpenAPIParser::RequestOperation, nil]
    def request_operation(http_method, request_path)
      OpenAPIParser::RequestOperation.create(http_method, request_path, @path_item_finder, @config)
    end

    # load another schema with shared config and schema_registry
    # @return [OpenAPIParser::Schemas::OpenAPI]
    def load_another_schema(uri)
      resolved_uri = resolve_uri(uri)
      return if resolved_uri.nil?

      loaded = @schema_registry[resolved_uri]
      return loaded if loaded

      OpenAPIParser.load_uri(resolved_uri, config: @config, schema_registry: @schema_registry)
    end

    private

      def resolve_uri(uri)
        if uri.absolute?
          uri
        else
          @uri&.merge(uri)
        end
      end
  end
end
