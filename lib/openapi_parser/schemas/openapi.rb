# TODO: info object
# TODO: servers object
# TODO: tags object
# TODO: externalDocs object

module OpenAPIParser::Schemas
  class OpenAPI < Base
    include OpenAPIParser::DefinitionValidatable

    def initialize(raw_schema, config)
      super('#', nil, self, raw_schema)
      @find_object_cache = {}
      @path_item_finder = OpenAPIParser::PathItemFinder.new(paths) if paths # invalid definition
      @config = config
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

    # return the definition is valid or not
    # @return Boolean
    def valid_definition?
      openapi_definition_errors.empty?
    end

    # return definition errors
    # @return Array
    def openapi_definition_errors
      @openapi_definition_errors ||= validate_definitions([])
    end
  end
end
