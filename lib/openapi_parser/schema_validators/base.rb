class OpenAPIParser::SchemaValidator
  class Base
    # @param [OpenAPIParser::SchemaValidator::Validatable] validatable
    def initialize(validatable, coerce_value)
      @validatable = validatable
      @coerce_value = coerce_value
    end

    attr_reader :validatable

    # @!attribute [r] validatable
    #   @return [OpenAPIParser::SchemaValidator::Validatable]

    # need override
    # @param [Array] _value
    # @param [OpenAPIParser::Schemas::Schema] _schema
    def coerce_and_validate(_value, _schema)
      raise 'need implement'
    end

    def validate_discriminator_schema(discriminator, value)
      property_name = discriminator.property_name

      # TODO: it's allowed to have discriminator without mapping, then we need to lookup discriminator.property_name
      # but the format is not the full path, just model name in the components
      mapping = discriminator.mapping

      resolved_schema = discriminator.root.find_object(mapping[value[property_name]])
      # TODO: throw error if component was not found
      validatable.validate_schema(value, resolved_schema)
    end
  end
end
