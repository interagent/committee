module Committee::Middleware
  class Base
    def initialize(app, options={})
      @app = app

      @error_class = options.fetch(:error_class, Committee::ValidationError)
      @params_key = options[:params_key] || "committee.params"
      @headers_key = options[:headers_key] || "committee.headers"
      @raise = options[:raise]
      @schema = get_schema(options)

      @validator_option = Committee::SchemaValidator::Option.new(@params_key, @headers_key, options, @schema)

      @router = @schema.build_router(validator_option: @validator_option, prefix: options[:prefix])
    end

    def call(env)
      request = Rack::Request.new(env)

      if @router.includes_request?(request)
        handle(request)
      else
        @app.call(request.env)
      end
    end

    private

    def get_schema(options)
      schema = options[:schema]

      if schema

        # Expect the type we want by now. If we don't have it, the user passed
        # something else non-standard in.
        if !schema.is_a?(Committee::Drivers::Schema)
          raise ArgumentError, "Committee: schema expected to be an instance of Committee::Drivers::Schema."
        end

        return schema
      end

      raise(ArgumentError, "Committee: need option `schema`")
    end

    def build_schema_validator(request)
      @router.build_schema_validator(request)
    end
  end
end
