# frozen_string_literal: true

module Committee
  module Drivers
    module OpenAPI3
      class Schema < ::Committee::Drivers::Schema
        attr_reader :open_api
        attr_reader :validator_option

        # @!attribute [r] open_api
        #   @return [OpenAPIParser::Schemas::OpenAPI]

        def initialize(driver, open_api)
          @open_api = open_api
          @driver = driver
        end

        def supports_stub?
          false
        end

        def driver # we don't use attr_reader because this method override super class
          @driver
        end

        def build_router(options)
          @validator_option = Committee::SchemaValidator::Option.new(options, self, :open_api_3)
          Committee::SchemaValidator::OpenAPI3::Router.new(self, @validator_option)
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
end
