module Committee
  class RequestValidator
    def initialize(options = {})
    end

    def call(link, params)
      if link.schema
        valid, errors = link.schema.validate(params)
        if !valid
          errors = error_messages(errors).join("\n")
          raise InvalidRequest, "Invalid request.\n\n#{errors}"
        end
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
