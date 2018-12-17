class OpenAPIParser::SchemaValidator
  class Options
    attr_reader :coerce_value, :datetime_coerce_class

    def initialize(coerce_value: nil, datetime_coerce_class: nil)
      @coerce_value = coerce_value
      @datetime_coerce_class = datetime_coerce_class
    end
  end
end
