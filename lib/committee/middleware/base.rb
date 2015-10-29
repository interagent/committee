module Committee::Middleware
  class Base
    def initialize(app, options={})
      @app = app

      @error_class = options.fetch(:error_class, Committee::ValidationError)
      @params_key = options[:params_key] || "committee.params"
      data = options[:schema] || raise("need option `schema`")
      if data.is_a?(String)
        warn_string_deprecated
        data = JSON.parse(data)
      end
      @raise = options[:raise]
      @schema = JsonSchema.parse!(data)
      @schema.expand_references!
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
