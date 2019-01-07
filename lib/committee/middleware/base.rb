module Committee::Middleware
  class Base
    def initialize(app, options={})
      @app = app

      @error_class = options.fetch(:error_class, Committee::ValidationError)

      @raise = options[:raise]
      @schema = self.class.get_schema(options)

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

    class << self
      def get_schema(options)
        schema = options[:schema]
        unless schema
          schema = Committee::Drivers::load_from_json(options[:json_file]) if options[:json_file]
          schema = Committee::Drivers::load_from_yaml(options[:yaml_file]) if options[:yaml_file]

          raise(ArgumentError, "Committee: need option `schema` or `json_file` or `yaml_file`") unless schema
        end

        # Expect the type we want by now. If we don't have it, the user passed
        # something else non-standard in.
        if !schema.is_a?(Committee::Drivers::Schema)
          raise ArgumentError, "Committee: schema expected to be an instance of Committee::Drivers::Schema."
        end

        return schema
      end
    end

    private

    def build_schema_validator(request)
      @router.build_schema_validator(request)
    end
  end
end
