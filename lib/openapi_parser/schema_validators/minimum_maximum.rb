class OpenAPIParser::SchemaValidator
  module MinimumMaximum
    # check enum value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def check_minimum_maximum(value, schema)
      include_min_max = schema.minimum || schema.exclusiveMinimum || schema.maximum || schema.exclusiveMaximum
      return [value, nil] unless include_min_max

      reference = schema.object_reference
      return [nil, OpenAPIParser::LessThanMinimum.new(value, reference)] if schema.minimum && value < schema.minimum
      return [nil, OpenAPIParser::LessThanExclusiveMinimum.new(value, reference)] if schema.exclusiveMinimum && value <= schema.exclusiveMinimum
      return [nil, OpenAPIParser::MoreThanMaximum.new(value, reference)] if schema.maximum && value > schema.maximum
      return [nil, OpenAPIParser::MoreThanExclusiveMaximum.new(value, reference)] if schema.exclusiveMaximum && value >= schema.exclusiveMaximum
      [value, nil]
    end
  end
end
