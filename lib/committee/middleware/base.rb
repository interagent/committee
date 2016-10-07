module Committee::Middleware
  class Base
    def initialize(app, options={})
      @app = app

      @driver = get_driver(options.fetch(:driver, :hyper_schema))
      @error_class = options.fetch(:error_class, Committee::ValidationError)
      @params_key = options[:params_key] || "committee.params"
      @raise = options[:raise]
      @schema = get_schema(options[:schema] ||
        raise(ArgumentError, "Committee: need option `schema`"))

      # Just a basic sanity check to make sure that we were given a sane
      # combination of driver and schema.
      if !@schema.is_a?(@driver.schema_class)
        raise ArgumentError, "Committee: schema (#{@schema.class.name}) " \
          "doesn't match driver schema (#{@driver.schema_class.name})."
      end

      @router = Committee::Router.new(@schema,
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

    # A driver can be a symbol or an instance of Committee::Drivers::Driver.
    def get_driver(driver)
      if driver.kind_of?(Committee::Drivers::Driver)
        driver
      elsif driver.is_a?(Symbol)
        Committee::Drivers.driver_from_name(driver)
      else
        raise ArgumentError, "Committee: driver expected to be a symbol or " \
          "an instance of Committee::Drivers::Driver."
      end
    end

    # A schema can be a data hash or an instance of Committee::Drivers::Schema.
    # For legacy reasons, we also allow it to be a string (which will be JSON
    # parsed) or an instance of JsonSchema::Schema (which will be wrapped in a
    # Committee schema class by the driver).
    def get_schema(schema)
      if schema.is_a?(String)
        warn_string_deprecated
        schema = JSON.parse(schema)
      end

      if schema.kind_of?(Committee::Drivers::Schema)
        schema
      elsif schema.is_a?(Hash)
        @driver.parse(schema)
      elsif schema.is_a?(JsonSchema::Schema)
        if @driver.name == :hyper_schema
          # Along with a special case here we've also special cased it within
          # the driver itself.
          @driver.parse(schema)
        else
          raise ArgumentError,
            "Committee: JSON schema data is only accepted for driver " \
            "hyper_schema. Try passing a hash instead."
        end
      else
        raise ArgumentError, "Committee: schema expected to be a hash or " \
          "an instance of Committee::Drivers::Schema."
      end
    end

    def warn_string_deprecated
      Committee.warn_deprecated("Committee: passing a string to `schema` option is deprecated; please send a deserialized hash instead.")
    end
  end
end
