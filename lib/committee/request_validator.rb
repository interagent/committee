module Committee
  class RequestValidator
    def initialize(options = {})
    end

    def call(link, params)
      if link.schema
        valid, errors = link.schema.validate(params)
        if !valid
          raise InvalidRequest,
            JsonSchema::SchemaError.aggregate(errors)
        end
      end
    end
  end
end
