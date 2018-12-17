# binding request data and operation object

class OpenAPIParser::RequestOperation
  class << self
    # @param [OpenAPIParser::PathItemFinder] path_item_finder
    def create(http_method, request_path, path_item_finder)
      endpoint, path_params = path_item_finder.operation_object(http_method, request_path)

      return nil unless endpoint

      self.new(endpoint, path_params)
    end
  end

  # @!attribute [r] operation_object
  #   @return [OpenAPIParser::Schemas::Operation, nil]
  # @!attribute [r] path_params
  #   @return [Hash{String => String}]
  attr_reader :operation_object, :path_params

  def initialize(operation_object, path_params)
    @operation_object = operation_object
    @path_params = path_params || {}
  end

  # support application/json only :(
  def validate_request_body(content_type, params, coerce)
    operation_object&.validate_request_body(content_type, params, coerce)
  end

  def validate_response_body(status_code, content_type, data, coerce)
    operation_object&.validate_response_body(status_code, content_type, data, coerce)
  end

  def validate_request_parameter(params, coerce)
    operation_object&.validate_request_parameter(params, coerce)
  end
end
