module Committee::Test
  module Methods
    def self.included(klass)
      klass.send(:include, Rack::Test::Methods)
    end

    def assert_schema_conform
      assert_schema_content_type

      @schema ||= Committee::Schema.new(File.read(schema_path))
      @router ||= Committee::Router.new(@schema)

      link_schema, type_schema = @router.routes_request?(last_request)

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

    def schema_path
      raise "Please override #schema_path."
    end
  end
end
