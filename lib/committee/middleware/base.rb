module Committee::Middleware
  class Base
    def initialize(app, options={})
      @app = app

      @error_class = options.fetch(:error_class, Committee::ValidationError)

      @raise = options[:raise]
      @schema = get_schema(options)

      @router = @schema.build_router(options)
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
