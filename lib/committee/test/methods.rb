# frozen_string_literal: true

module Committee
  module Test
    module Methods
      def assert_schema_conform
        assert_request_schema_confirm unless old_behavior
        assert_response_schema_confirm
      end

      def assert_request_schema_confirm
        unless schema_validator.link_exist?
          request = "`#{request_object.request_method} #{request_object.path_info}` undefined in schema."
          raise Committee::InvalidRequest.new(request)
        end

        schema_validator.request_validate(request_object)
      end

      def assert_response_schema_confirm
        unless schema_validator.link_exist?
          response = "`#{request_object.request_method} #{request_object.path_info}` undefined in schema."
          raise Committee::InvalidResponse.new(response)
        end

        status, headers, body = response_data

        current_schema_coverage&.update_coverage!(request_object.path_info, request_object.request_method, status)
        schema_coverage&.update_coverage!(request_object.path_info, request_object.request_method, status)

        schema_validator.response_validate(status, headers, [body], true) if validate_response?(status)
      end

      def committee_options
        raise "please set options"
      end

      def request_object
        raise "please set object like 'last_request'"
      end

      def response_data
        raise "please set response data like 'last_response.status, last_response.headers, last_response.body'"
      end

      def validate_response?(status)
        Committee::Middleware::ResponseValidation.validate?(status, committee_options.fetch(:validate_success_only, false))
      end

      def schema
        @schema ||= Committee::Middleware::Base.get_schema(committee_options)
      end

      def router
        @router ||= schema.build_router(committee_options)
      end

      def schema_validator
        @schema_validator ||= router.build_schema_validator(request_object)
      end

      def current_schema_coverage
        return nil unless schema.is_a?(Committee::Drivers::OpenAPI3::Schema)

        @current_schema_coverage ||= SchemaCoverage.new(schema)
      end

      def schema_coverage
        return nil unless schema.is_a?(Committee::Drivers::OpenAPI3::Schema)

        coverage = committee_options.fetch(:schema_coverage, nil)

        coverage.is_a?(SchemaCoverage) ? coverage : nil
      end

      def old_behavior
        old_assert_behavior = committee_options.fetch(:old_assert_behavior, nil)
        if old_assert_behavior.nil?
          Committee.warn_deprecated('Now assert_schema_conform check response schema only. but we will change check request and response in future major version. so if you want to conform response only, please use assert_response_schema_confirm, or you can suppress this message and keep old behavior by setting old_assert_behavior=true.')
          old_assert_behavior = true
        end
        old_assert_behavior
      end
    end
  end
end
