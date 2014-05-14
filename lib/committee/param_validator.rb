module Committee
  class ParamValidator
    def initialize(options = {})
    end

    def call(link, params)
      if link.schema
        valid, errors = link.schema.validate(params)
        if !valid
          raise InvalidParams,
            JsonSchema::SchemaError.aggregate(errors)
        end
      end
    end
  end
end
