module Committee
  class RequestValidator
    def initialize(options = {})
    end

    def call(link, params)
      if link.schema
        valid, errors = link.schema.validate(params)
        if !valid
          errors = JsonSchema::SchemaError.aggregate(errors).join("\n")
          raise InvalidRequest, "Invalid request.\n\n#{errors}"
        end
      end
    end
  end
end
