module Committee
  class ResponseValidator
    def initialize(link)
      @link = link

      # we should eventually move off of validating against parent schema too
      # ... this is a Herokuism and not in the specification
      schema = link.target_schema || link.parent
      @validator = JsonSchema::Validator.new(schema)
    end

    def self.validate?(status)
      status != 204 and @validate_errors || (200...300).include?(status)
    end

    def call(status, headers, data)
      unless status == 204 # 204 No Content
        response = Rack::Response.new(data, status, headers)
        check_content_type!(response)
      end

      if @link.rel == "instances" && !@link.target_schema
        if !data.is_a?(Array)
          raise InvalidResponse, "List endpoints must return an array of objects."
        end

        # only consider the first object during the validation from here on
        # (but only in cases where `targetSchema` is not set)
        data = data[0]

        # if the array was empty, allow it through
        return if data == nil
      end

      if !@validator.validate(data)
        errors = JsonSchema::SchemaError.aggregate(@validator.errors).join("\n")
        raise InvalidResponse, "Invalid response.\n\n#{errors}"
      end
    end

    private

    def response_media_type(response)
      response.content_type.to_s.split(";").first.to_s
    end

    def check_content_type!(response)
      unless Rack::Mime.match?(response_media_type(response), @link.enc_type)
        raise Committee::InvalidResponse,
          %{"Content-Type" response header must be set to "#{@link.enc_type}".}
      end
    end
  end
end
