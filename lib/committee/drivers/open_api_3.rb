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

    def name
      :open_api_3
    end

    # TODO: check it's need?
    def schema_class
      Committee::Drivers::OpenAPI3::Schema
    end

    def parse(definitions)
      Schema.new(self, definitions)
    end

    class Schema < Committee::Drivers::Schema
      attr_reader :definitions

      def initialize(driver, definitions)
        @definitions = definitions
        @driver = driver
      end

      def driver # we don't use attr_reader because this method override super class
        @driver
      end

      def build_router(options)
        validator_option = Committee::SchemaValidator::Option.new(options, self, :hyper_schema)
        Committee::SchemaValidator::OpenAPI3::Router.new(self, validator_option)
      end

      # OpenAPI3 only
      def operation_object(path, method)
        return nil unless definitions.raw['paths'][path]
        path_item_object = definitions.path_by_path(path)

        return nil unless path_item_object.raw[method]
        endpoint = path_item_object.endpoint_by_method(method)

        Committee::SchemaValidator::OpenAPI3::OperationObject.new(endpoint)
      end
    end
  end
end
