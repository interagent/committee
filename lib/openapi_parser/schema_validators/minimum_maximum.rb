class OpenAPIParser::SchemaValidator
  module MinimumMaximum
    # check minimum and maximum value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def check_minimum_maximum(value, schema)
      include_min_max = schema.minimum || schema.maximum
      return [value, nil] unless include_min_max

      validate(value, schema)
      [value, nil]
    rescue OpenAPIParser::OpenAPIError => e
      return [nil, e]
    end

    private

      def validate(value, schema)
        reference = schema.object_reference

        if schema.minimum
          if schema.exclusiveMinimum && value <= schema.minimum
            raise OpenAPIParser::LessThanExclusiveMinimum.new(value, reference)
          elsif value < schema.minimum
            raise OpenAPIParser::LessThanMinimum.new(value, reference)
          end
        end

        if schema.maximum
          if schema.exclusiveMaximum && value >= schema.maximum
            raise OpenAPIParser::MoreThanExclusiveMaximum.new(value, reference)
          elsif value > schema.maximum
            raise OpenAPIParser::MoreThanMaximum.new(value, reference)
          end
        end
      end
  end
end
