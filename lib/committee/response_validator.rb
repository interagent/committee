module Committee
  class ResponseValidator
    def initialize(link)
      @link = link
      @validator = JsonSchema::Validator.new(link.parent)
    end

    def call(data)
      if @link.rel == "instances"
        if !data.is_a?(Array)
          raise InvalidResponse, "List endpoints must return an array of objects."
        end
        # only consider the first object during the validation from here on
        data = data[0]
      end

      if !@validator.validate(data)
        raise InvalidResponse,
          JsonSchema::SchemaError.aggregate(@validator.errors)
      end
    end
  end
end
