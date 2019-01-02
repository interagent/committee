class OpenAPIParser::Config
  def initialize(config)
    @config = config
  end

  def datetime_coerce_class
    @config[:datetime_coerce_class]
  end

  def coerce_value
    @config[:coerce_value]
  end

  def expand_reference
    @config.fetch(:expand_reference, true)
  end

  def strict_response_validation
    @config.fetch(:strict_response_validation, false)
  end

  def validate_header
    @config.fetch(:validate_header, true)
  end

  # @return [OpenAPIParser::SchemaValidator::Options]
  def request_validator_options
    @request_validator_options ||= OpenAPIParser::SchemaValidator::Options.new(coerce_value: coerce_value,
                                                                               datetime_coerce_class: datetime_coerce_class,
                                                                               validate_header: validate_header)
  end

  alias_method :request_body_options, :request_validator_options
  alias_method :path_params_options, :request_validator_options

  # @return [OpenAPIParser::SchemaValidator::ResponseValidateOptions]
  def response_validate_options
    @response_validate_options ||= OpenAPIParser::SchemaValidator::ResponseValidateOptions.
        new(strict: strict_response_validation, validate_header: validate_header)
  end
end
