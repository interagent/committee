module Committee::Middleware
  class Base
    def initialize(app, options={})
      @app = app

      @error_class = options.fetch(:error_class, Committee::ValidationError)
      @params_key = options[:params_key] || "committee.params"
      @headers_key = options[:headers_key] || "committee.headers"
      @raise = options[:raise]
      @schema = get_schema(options)

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

    # For modern use of the library a schema should be an instance of
    # Committee::Drivers::Schema so that we know that all the computationally
    # difficult parsing is already done by the time we try to handle any
    # request.
    #
    # However, for reasons of backwards compatibility we also allow schema
    # input to be a string, a data hash, or a JsonSchema::Schema. In the former
    # two cases we just parse as if we were sent hyper-schema. In the latter,
    # we have the hyper-schema driver wrap it in a new Committee object.
    def get_schema(options)
      schema = options[:schema]
      unless schema
        schema = Committee::Drivers::load_from_json(options[:json_file]) if options[:json_file]

        raise(ArgumentError, "Committee: need option `schema` or json_file") unless schema
      end

      # These are in a separately conditional ladder so that we only show the
      # user one warning.
      if schema.is_a?(String)
        warn_string_deprecated
      elsif schema.is_a?(Hash)
        warn_hash_deprecated
      elsif schema.is_a?(JsonSchema::Schema)
        warn_json_schema_deprecated
      end

      if schema.is_a?(String)
        schema = JSON.parse(schema)
      end

      if schema.is_a?(Hash) || schema.is_a?(JsonSchema::Schema)
        driver = Committee::Drivers::HyperSchema.new

        # The driver itself has its own special cases to be able to parse
        # either a hash or JsonSchema::Schema object.
        schema = driver.parse(schema)
      end

      # Expect the type we want by now. If we don't have it, the user passed
      # something else non-standard in.
      if !schema.is_a?(Committee::Drivers::Schema)
        raise ArgumentError, "Committee: schema expected to be a hash or " \
          "an instance of Committee::Drivers::Schema."
      end

      schema
    end

    def warn_json_schema_deprecated
      Committee.warn_deprecated("Committee: passing a JsonSchema::Schema to schema " \
        "option is deprecated; please send a driver object instead.")
    end

    def warn_hash_deprecated
      Committee.warn_deprecated("Committee: passing a hash to schema " \
        "option is deprecated; please send a driver object instead.")
    end

    def warn_string_deprecated
      Committee.warn_deprecated("Committee: passing a string to schema " \
        "option is deprecated; please send a driver object instead.")
    end
  end
end
