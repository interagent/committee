# binding request data and operation object

class OpenAPIParser::RequestOperation
  class << self
    # @param [OpenAPIParser::Config] config
    # @param [OpenAPIParser::PathItemFinder] path_item_finder
    # @return [OpenAPIParser::RequestOperation, nil]
    def create(http_method, request_path, path_item_finder, config)
      operation, original_path, path_params = path_item_finder.operation_object(http_method, request_path)

      return nil unless operation

      self.new(http_method, original_path, operation, path_params, config)
    end
  end

  # @!attribute [r] operation_object
  #   @return [OpenAPIParser::Schemas::Operation]
  # @!attribute [r] path_params
  #   @return [Hash{String => String}]
  # @!attribute [r] config
  #   #   @return [OpenAPIParser::Config]
  # @!attribute [r] http_method
  #   @return [String]
  # @!attribute [r] original_path
  #   @return [String]
  attr_reader :operation_object, :path_params, :config, :http_method, :original_path

  # @param [OpenAPIParser::Config] config
  def initialize(http_method, original_path, operation_object, path_params, config)
    @http_method = http_method.to_s
    @original_path = original_path
    @operation_object = operation_object
    @path_params = path_params || {}
    @config = config
  end

  def validate_path_params(options = nil)
    options ||= config.path_params_options
    operation_object&.validate_path_params(path_params, options)
  end

  # support application/json only :(
  def validate_request_body(content_type, params, options = nil)
    options ||= config.request_body_options
    operation_object&.validate_request_body(content_type, params, options)
  end

  # @param [Integer] status_code
  def validate_response_body(status_code, content_type, data)
    operation_object&.validate_response_body(status_code, content_type, data)
  end

  def validate_request_parameter(params, options = nil)
    options ||= config.request_validator_options
    operation_object&.validate_request_parameter(params, options)
  end
end
