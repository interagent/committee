# frozen_string_literal: true

module Committee
  module Drivers
    module OpenAPI3
      class Driver < ::Committee::Drivers::Driver
        def default_coerce_date_times
          true
        end

        # Whether parameters that were form-encoded will be coerced by default.
        def default_coerce_form_params
          true
        end

        def default_allow_get_body
          false
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

        def default_validate_success_only
          false
        end

        def name
          :open_api_3
        end

        # @return [Committee::Drivers::OpenAPI3::Schema]
        def parse(open_api)
          schema_class.new(self, open_api)
        end

        def schema_class
          Committee::Drivers::OpenAPI3::Schema
        end
      end
    end
  end
end
