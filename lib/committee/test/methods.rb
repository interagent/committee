# frozen_string_literal: true

module Committee
  module Test
    module Methods
      def assert_schema_conform(expected_status = nil)
        assert_request_schema_confirm unless old_behavior
        assert_response_schema_confirm(expected_status)
      end

      def assert_request_schema_confirm
        unless schema_validator.link_exist?
          request = "`#{request_object.request_method} #{request_object.path_info}` undefined in schema (prefix: #{committee_options[:prefix].inspect})."
          raise Committee::InvalidRequest.new(request)
        end

        schema_validator.request_validate(request_object)
      end

      def assert_response_schema_confirm(expected_status = nil)
        unless schema_validator.link_exist?
          response = "`#{request_object.request_method} #{request_object.path_info}` undefined in schema (prefix: #{committee_options[:prefix].inspect})."
          raise Committee::InvalidResponse.new(response)
        end

        status, headers, body = response_data

        if expected_status.nil?
          Committee.need_good_option('Pass expected response status code to check it against the corresponding schema explicitly.')
        elsif expected_status != status
          response = "Expected `#{expected_status}` status code, but it was `#{status}`."
          raise Committee::InvalidResponse.new(response)
        end

        if schema_coverage
          operation_object = router.operation_object(request_object)
          schema_coverage&.update_response_coverage!(operation_object.original_path, operation_object.http_method, status)
        end

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

      def schema_coverage
        return nil unless schema.is_a?(Committee::Drivers::OpenAPI3::Schema)

        coverage = committee_options.fetch(:schema_coverage, nil)

        coverage.is_a?(SchemaCoverage) ? coverage : nil
      end

      def old_behavior
        committee_options.fetch(:old_assert_behavior, false)
      end
    end
  end
end
