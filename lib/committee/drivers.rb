# frozen_string_literal: true

module Committee
  module Drivers
    # Gets a driver instance from the specified name. Raises ArgumentError for
    # an unknown driver name.
    def self.driver_from_name(name)
      case name
      when :hyper_schema
        Committee::Drivers::HyperSchema::Driver.new
      when :open_api_2
        Committee::Drivers::OpenAPI2::Driver.new
      when :open_api_3
        Committee::Drivers::OpenAPI3::Driver.new
      else
        raise ArgumentError, %{Committee: unknown driver "#{name}".}
      end
    end

    # load and build drive from JSON file
    # @param [String] schema_path
    # @return [Committee::Driver]
    def self.load_from_json(schema_path)
      load_from_data(JSON.parse(File.read(schema_path)), schema_path)
    end

    # load and build drive from YAML file
    # @param [String] schema_path
    # @return [Committee::Driver]
    def self.load_from_yaml(schema_path)
      load_from_data(YAML.load_file(schema_path), schema_path)
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
    def self.load_from_data(hash, schema_path = nil)
      if hash['openapi']&.start_with?('3.0.')
        openapi = OpenAPIParser.parse_with_filepath(hash, schema_path)
        return Committee::Drivers::OpenAPI3::Driver.new.parse(openapi)
      end

      driver = if hash['swagger'] == '2.0'
                 Committee::Drivers::OpenAPI2::Driver.new
               else
                 Committee::Drivers::HyperSchema::Driver.new
               end

      driver.parse(hash)
    end
  end
end

require_relative "drivers/driver"
require_relative "drivers/schema"
require_relative "drivers/hyper_schema"
require_relative "drivers/open_api_2"
require_relative "drivers/open_api_3"
