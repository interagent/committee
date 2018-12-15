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
end
