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
        errors = error_messages(@validator.errors).join("\n")
        raise InvalidResponse, "Invalid response.\n\n#{errors}"
      end
    end

    private

    def error_messages(errors)
      errors.map do |error|
        if error.schema
          %{At "#{error.schema.uri}": #{error.message}}
        else
          error.message
        end
      end
    end
  end
end
