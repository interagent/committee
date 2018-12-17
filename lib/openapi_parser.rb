require 'time'

require 'openapi_parser/version'
require 'openapi_parser/config'
require 'openapi_parser/errors'
require 'openapi_parser/concern'
require 'openapi_parser/schemas'
require 'openapi_parser/path_item_finder'
require 'openapi_parser/request_operation'
require 'openapi_parser/schema_validator'
require 'openapi_parser/parameter_validator'
require 'openapi_parser/reference_expander'

module OpenAPIParser
  class << self
    # @return [OpenAPIParser::Schemas::OpenAPI]
    def parse(schema, config = {})
      c = Config.new(config)
      root = Schemas::OpenAPI.new(schema, c)

      OpenAPIParser::ReferenceExpander.expand(root) if c.expand_reference

      root
    end
  end
end
