module Committee::Test
  module Methods
    def assert_schema_conform
      assert_schema_content_type

      @schema ||= Committee::Schema.new(schema_contents)
      @router ||= Committee::Router.new(@schema)

      link_schema, type_schema =
        @router.routes_request?(last_request, prefix: schema_url_prefix)

      unless link_schema
        response = "`#{last_request.request_method} #{last_request.path_info}` undefined in schema."
        raise Committee::InvalidResponse.new(response)
      end

      data = MultiJson.decode(last_response.body)
      Committee::ResponseValidator.new(
        data,
        @schema,
        link_schema,
        type_schema
      ).call
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
      File.read(schema_path)
    end

    def schema_path
      raise "Please override #schema_path."
    end

    def schema_url_prefix
      nil
    end
  end
end
