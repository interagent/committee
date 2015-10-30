module Committee::Middleware
  class Base
    def initialize(app, options={})
      @app = app

      @error_class = options.fetch(:error_class, Committee::ValidationError)
      @params_key = options[:params_key] || "committee.params"
      @raise = options[:raise]

      schema = options[:schema] || raise("need option `schema`")
      if schema.is_a?(String)
        warn_string_deprecated
        schema = JSON.parse(schema)
      end
      if schema.is_a?(Hash)
        schema = JsonSchema.parse!(schema)
        schema.expand_references!
      end
      @schema = schema

      @router = Committee::Router.new(@schema, options)
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

    def warn_string_deprecated
      Committee.warn_deprecated("Committee: passing a string to `schema` option is deprecated; please send a deserialized hash instead.")
    end
  end
end
