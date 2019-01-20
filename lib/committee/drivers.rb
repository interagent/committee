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
      when :open_api_3
        Committee::Drivers::OpenAPI3.new
      else
        raise ArgumentError, %{Committee: unknown driver "#{name}".}
      end
    end

    # load and build drive from JSON file
    # @param [String] schema_path
    # @return [Committee::Driver]
    def self.load_from_json(schema_path)
      load_from_data(JSON.parse(File.read(schema_path)))
    end

    # load and build drive from YAML file
    # @param [String] schema_path
    # @return [Committee::Driver]
    def self.load_from_yaml(schema_path)
      load_from_data(YAML.load_file(schema_path))
    end

    # load and build drive from file
    # @param [String] schema_path
    # @return [Committee::Driver]
    def self.load_from_file(schema_path)
      case File.extname(schema_path)
      when '.json'
        load_from_json(schema_path)
      when '.yaml', '.yml'
        load_from_yaml(schema_path)
      else
        raise "Committee only supports the following file extensions: '.json', '.yaml', '.yml'"
      end
    end

    # load and build drive from Hash object
    # @param [Hash] hash
    # @return [Committee::Driver]
    def self.load_from_data(hash)
      if hash['openapi'] == '3.0.0'
        parser = OpenAPIParser.parse(hash)
        return Committee::Drivers::OpenAPI3.new.parse(parser)
      end

      driver = if hash['swagger'] == '2.0'
                 Committee::Drivers::OpenAPI2.new
               else
                 Committee::Drivers::HyperSchema.new
               end

      driver.parse(hash)
    end

    # Driver is a base class for driver implementations.
    class Driver
      # Whether parameters that were form-encoded will be coerced by default.
      def default_coerce_form_params
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

    # Schema is a base class for driver schema implementations.
    class Schema
      # A link back to the derivative instace of Committee::Drivers::Driver
      # that create this schema.
      def driver
        raise "needs implementation"
      end

      def build_router(options)
        raise "needs implementation"
      end

      # Stubs are supported in JSON Hyper-Schema and OpenAPI 2, but not yet in OpenAPI 3
      def supports_stub?
        true
      end
    end
  end
end