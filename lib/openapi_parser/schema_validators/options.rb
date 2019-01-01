class OpenAPIParser::SchemaValidator
  class Options
    # @!attribute [r] coerce_value
    #   @return [Boolean] coerce value option on/off
    # @!attribute [r] datetime_coerce_class
    #   @return [Object, nil] coerce datetime string by this Object class
    attr_reader :coerce_value, :datetime_coerce_class

    def initialize(coerce_value: nil, datetime_coerce_class: nil)
      @coerce_value = coerce_value
      @datetime_coerce_class = datetime_coerce_class
    end
  end

  # response body validation option
  class ResponseValidateOptions
    # @!attribute [r] strict
    #   @return [Boolean] validate by strict (when not exist definition, raise error)
    attr_reader :strict

    def initialize(strict: false)
      @strict = strict
    end
  end
end
