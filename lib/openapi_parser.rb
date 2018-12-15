require 'openapi_parser/version'
require 'openapi_parser/errors'
require 'openapi_parser/concern'
require 'openapi_parser/schemas'
require 'openapi_parser/path_item_finder'
require 'openapi_parser/request_operation'
require 'openapi_parser/schema_validator'

module OpenAPIParser
  class << self
    # @param [OpenAPIParser::Schemas::OpenAPI]
    def parse(schema)
      Schemas::OpenAPI.new(schema)
    end
  end
end
