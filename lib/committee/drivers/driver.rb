# frozen_string_literal: true

module Committee
  module Drivers
    # Driver is a base class for driver implementations.
    class Driver
      # Whether parameters that were form-encoded will be coerced by default.
      def default_coerce_form_params
        raise "needs implementation"
      end

      # Use GET request body to request parameter (request body merge to parameter)
      def default_allow_get_body
        raise "needs implementation"
      end

      # Whether parameters in a request's path will be considered and coerced
      # by default.
      def default_path_params
        raise "needs implementation"
      end

      # Whether parameters in a request's query string will be considered and
      # coerced by default.
      def default_query_params
        raise "needs implementation"
      end

      def name
        raise "needs implementation"
      end

      # Parses an API schema and builds a set of route definitions for use with
      # Committee.
      #
      # The expected input format is a data hash with keys as strings (as
      # opposed to symbols) like the kind produced by JSON.parse or YAML.load.
      def parse(data)
        raise "needs implementation"
      end

      def schema_class
        raise "needs implementation"
      end
    end
  end
end
