module OpenAPIParser
  class OpenAPIError < StandardError
    def initialize(reference)
      @reference = reference
    end
  end

  class ValidateError < OpenAPIError
    def initialize(data, type, reference)
      super(reference)
      @data = data
      @type = type
    end

    def message
      "#{@data} class is #{@data.class} but it's not valid #{@type} in #{@reference}"
    end

    class << self
      # create ValidateError for SchemaValidator return data
      # @param [Object] value
      # @param [OpenAPIParser::Schemas::Base] schema
      def build_error_result(value, schema)
        [nil, OpenAPIParser::ValidateError.new(value, schema.type, schema.object_reference)]
      end
    end
  end

  class NotNullError < OpenAPIError
    def message
      "#{@reference} don't allow null"
    end
  end

  class NotExistRequiredKey < OpenAPIError
    def initialize(keys, reference)
      super(reference)
      @keys = keys
    end

    def message
      "required parameters #{@keys.join(",")} not exist in #{@reference}"
    end
  end

  class NotExistPropertyDefinition < OpenAPIError
    def initialize(keys, reference)
      super(reference)
      @keys = keys
    end

    def message
      "properties #{@keys.join(",")} are not defined in #{@reference}"
    end
  end

  class NotExistDiscriminatorMappedSchema < OpenAPIError
    def initialize(mapped_schema_reference, reference)
      super(reference)
      @mapped_schema_reference = mapped_schema_reference
    end

    def message
      "discriminator mapped schema #{@mapped_schema_reference} does not exist in #{@reference}"
    end
  end

  class NotExistDiscriminatorPropertyName < OpenAPIError
    def initialize(key, value, reference)
      super(reference)
      @key   = key
      @value = value
    end

    def message
      "discriminator propertyName #{@key} does not exist in value #{@value} in #{@reference}"
    end
  end

  class NotOneOf < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@value} isn't one of in #{@reference}"
    end
  end

  class NotAnyOf < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@value} isn't any of in #{@reference}"
    end
  end

  class NotEnumInclude < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@value} isn't include enum in #{@reference}"
    end
  end

  class InvalidPattern < OpenAPIError
    def initialize(value, pattern, reference)
      super(reference)
      @value = value
      @pattern = pattern
    end

    def message
      "#{@value} isn't match #{@pattern} in #{@reference}"
    end
  end

  class NotExistStatusCodeDefinition < OpenAPIError
    def message
      "don't exist status code definition in #{@reference}"
    end
  end

  class NotExistContentTypeDefinition < OpenAPIError
    def message
      "don't exist response definition #{@reference}"
    end
  end
end
