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

  def request_validator_options
    @request_options ||= OpenAPIParser::SchemaValidator::Options.new(coerce_value: coerce_value, datetime_coerce_class: datetime_coerce_class)
  end
end
