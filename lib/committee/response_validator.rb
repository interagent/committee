module Committee
  class ResponseValidator
    def initialize(link)
      @link = link

      # we should eventually move off of validating against parent schema too
      # ... this is a Herokuism and not in the specification
      schema = link.target_schema || link.parent
      @validator = JsonSchema::Validator.new(schema)
    end

    def call(headers, data)
      check_content_type!(headers)

      if @link.rel == "instances"
        if !data.is_a?(Array)
          raise InvalidResponse, "List endpoints must return an array of objects."
        end
        # only consider the first object during the validation from here on
        data = data[0]
      end

      if !@validator.validate(data)
        errors = JsonSchema::SchemaError.aggregate(@validator.errors).join("\n")
        raise InvalidResponse, "Invalid response.\n\n#{errors}"
      end
    end

    private

    def check_content_type!(headers)
      match = [%r{application/json}, %r{application/schema\+json}].any? { |m|
        headers["Content-Type"] =~ m
      }
      unless match
        raise Committee::InvalidResponse,
          %{"Content-Type" response header must be set to "application/json".}
      end
    end
  end
end
