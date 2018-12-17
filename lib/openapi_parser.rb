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

module OpenAPIParser
  class << self
    # @param [OpenAPIParser::Schemas::OpenAPI]
    def parse(schema, config = {})
      Schemas::OpenAPI.new(schema, Config.new(config))
    end
  end
end
