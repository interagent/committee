module Committee::Drivers
  class OpenAPI3 < Committee::Drivers::Driver
    # Whether parameters that were form-encoded will be coerced by default.
    def default_coerce_form_params
      true
    end

    # Whether parameters in a request's path will be considered and coerced by
    # default.
    def default_path_params
      true
    end

    # Whether parameters in a request's query string will be considered and
    # coerced by default.
    def default_query_params
      true
    end

    def default_coerce_date_times
      true
    end

    def name
      :open_api_3
    end

    def schema_class
      Committee::Drivers::OpenAPI3::Schema
    end

    # @return [Committee::Drivers::OpenAPI3::Schema]
    def parse(open_api)
      schema_class.new(self, open_api)
    end

    class Schema < Committee::Drivers::Schema
      attr_reader :open_api

      # @!attribute [r] open_api
      #   @return [OpenAPIParser::Schemas::OpenAPI]

      def initialize(driver, open_api)
        @open_api = open_api
        @driver = driver
      end

      def support_stub?
        false
      end

      def driver # we don't use attr_reader because this method override super class
        @driver
      end

      def build_router(options)
        validator_option = Committee::SchemaValidator::Option.new(options, self, :open_api_3)
        Committee::SchemaValidator::OpenAPI3::Router.new(self, validator_option)
      end

      # OpenAPI3 only
      def operation_object(path, method)
        request_operation = open_api.request_operation(method, path)
        return nil unless request_operation

        Committee::SchemaValidator::OpenAPI3::OperationWrapper.new(request_operation)
      end
    end
  end
end
