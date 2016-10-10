module Committee
  module Drivers
    # Gets a driver instance from the specified name. Raises ArgumentError for
    # an unknown driver name.
    def self.driver_from_name(name)
      case name
      when :hyper_schema
        Committee::Drivers::HyperSchema.new
      when :open_api_2
        Committee::Drivers::OpenAPI2.new
      else
        raise ArgumentError, %{Committee: unknown driver "#{name}".}
      end
    end

    # Driver is a base class for driver implementations.
    class Driver
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

    # Schema is a base class for driver schema implementations.
    class Schema
      # A link back to the derivative instace of Committee::Drivers::Driver
      # that create this schema.
      def driver
        raise "needs implementation"
      end
    end
  end
end
