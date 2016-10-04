module Committee::Middleware
  class Base
    def initialize(app, options={})
      @app = app

      @driver = initialize_driver(options.fetch(:driver, :hyper_schema))
      @error_class = options.fetch(:error_class, Committee::ValidationError)
      @params_key = options[:params_key] || "committee.params"
      @raise = options[:raise]

      schema = options[:schema] || raise("need option `schema`")
      if schema.is_a?(String)
        warn_string_deprecated
        schema = JSON.parse(schema)
      end

      @schema = @driver.parse(schema)

      @router = Committee::Router.new(@schema,
        driver: @driver,
        prefix: options[:prefix]
      )
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

    def initialize_driver(name)
      case name
      when :hyper_schema
        Committee::Drivers::HyperSchema.new
      when :open_api_2
        Committee::Drivers::OpenAPI2.new
      else
        raise ArgumentError, %{Committee: unknown driver "#{name}"}
      end
    end

    def warn_string_deprecated
      Committee.warn_deprecated("Committee: passing a string to `schema` option is deprecated; please send a deserialized hash instead.")
    end
  end
end
