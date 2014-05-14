module Committee::Test
  module Methods
    def assert_schema_conform
      assert_schema_content_type

      if (data = schema_contents).is_a?(String)
        warn_string_deprecated
        data = MultiJson.decode(data)
      end

      @schema ||= JsonSchema.parse!(data)
      @router ||= Committee::Router.new(@schema)

      link =
        @router.routes_request?(last_request, prefix: schema_url_prefix)
      unless link
        response = "`#{last_request.request_method} #{last_request.path_info}` undefined in schema."
        raise Committee::InvalidResponse.new(response)
      end

      data = MultiJson.decode(last_response.body)
      Committee::ResponseValidator.new(link).call(data)
    end

    def assert_schema_content_type
      unless last_response.headers["Content-Type"] =~ %r{application/json}
        raise Committee::InvalidResponse,
          %{"Content-Type" response header must be set to "application/json".}
      end
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
