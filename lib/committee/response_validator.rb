module Committee
  class ResponseValidator
    def initialize(data, schema, link, type_schema)
      @data = data
      @schema = schema
      @link = link
      @type_schema = type_schema
      @validator = JsonSchema::Validator.new(@type_schema)
    end

    def call
      data = if @link.rel == "instances"
        if !@data.is_a?(Array)
          raise InvalidResponse, "List endpoints must return an array of objects."
        end
        # only consider the first object during the validation from here on
        @data[0]
      else
        @data
      end

      if !@validator.validate(data)
        raise InvalidResponse,
          JsonSchema::SchemaError.aggregate(@validator.errors)
      end
    end
  end
end
