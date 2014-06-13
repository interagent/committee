module Committee::Test
  module Methods
    def assert_schema_conform
      if (data = schema_contents).is_a?(String)
        warn_string_deprecated
        data = MultiJson.decode(data)
      end

      @schema ||= begin
        schema = JsonSchema.parse!(data)
        schema.expand_references!
        schema
      end
      @router ||= Committee::Router.new(@schema, prefix: schema_url_prefix)

      unless link = @router.find_request_link(last_request)
        response = "`#{last_request.request_method} #{last_request.path_info}` undefined in schema."
        raise Committee::InvalidResponse.new(response)
      end

      data = MultiJson.decode(last_response.body)
      Committee::ResponseValidator.new(link).call(last_response.headers, data)
    end

    def assert_schema_content_type
      Committee.warn_deprecated("Committee: use of #assert_schema_content_type is deprecated; use #assert_schema_conform instead.")
    end

    # can be overridden alternatively to #schema_path in case the schema is
    # easier to access as a string
    # blob
    def schema_contents
      MultiJson.decode(File.read(schema_path))
    end

    def schema_path
      raise "Please override #schema_contents or #schema_path."
    end

    def schema_url_prefix
      nil
    end

    def warn_string_deprecated
      Committee.warn_deprecated("Committee: returning a string from `#schema_contents` is deprecated; please return a deserialized hash instead.")
    end
  end
end
