# binding request data and operation object

class OpenAPIParser::RequestOperation
  class << self
    # @param [OpenAPIParser::Config] config
    # @param [OpenAPIParser::PathItemFinder] path_item_finder
    def create(http_method, request_path, path_item_finder, config)
      endpoint, path_params = path_item_finder.operation_object(http_method, request_path)

      return nil unless endpoint

      self.new(endpoint, path_params, config)
    end
  end

  # @!attribute [r] operation_object
  #   @return [OpenAPIParser::Schemas::Operation, nil]
  # @!attribute [r] path_params
  #   @return [Hash{String => String}]
  # @!attribute [r] config
  #   @return [OpenAPIParser::Config]
  attr_reader :operation_object, :path_params, :config

  # @param [OpenAPIParser::Config] config
  def initialize(operation_object, path_params, config)
    @operation_object = operation_object
    @path_params = path_params || {}
    @config = config
  end

  # support application/json only :(
  # @param [OpenAPIParser::SchemaValidator::Options] options
  def validate_request_body(content_type, params, options)
    operation_object&.validate_request_body(content_type, params, options)
  end

  # @param [OpenAPIParser::SchemaValidator::Options] options
  def validate_response_body(status_code, content_type, data, options)
    operation_object&.validate_response_body(status_code, content_type, data, options)
  end

  def validate_request_parameter(params)
    operation_object&.validate_request_parameter(params, config.request_validator_options)
  end
end
