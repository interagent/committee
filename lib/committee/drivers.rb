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
    def self.load_from_json(schema_path, parser_options: {})
      load_from_data(JSON.parse(File.read(schema_path)), schema_path, parser_options: parser_options)
    end

    # load and build drive from YAML file
    # @param [String] schema_path
    # @return [Committee::Driver]
    def self.load_from_yaml(schema_path, parser_options: {})
      data = YAML.respond_to?(:unsafe_load_file) ? YAML.unsafe_load_file(schema_path) : YAML.load_file(schema_path)
      load_from_data(data, schema_path, parser_options: parser_options)
    end

    # load and build drive from file
    # @param [String] schema_path
    # @return [Committee::Driver]
    def self.load_from_file(schema_path, parser_options: {})
      case File.extname(schema_path)
      when '.json'
        load_from_json(schema_path, parser_options: parser_options)
      when '.yaml', '.yml'
        load_from_yaml(schema_path, parser_options: parser_options)
      else
        raise "Committee only supports the following file extensions: '.json', '.yaml', '.yml'"
      end
    end

    # load and build drive from Hash object
    # @param [Hash] hash
    # @return [Committee::Driver]
    def self.load_from_data(hash, schema_path = nil, parser_options: {})
      if hash['openapi']&.start_with?('3.0.')
        # From the next major version, we want to ensure `{ strict_reference_validation: true }`
        # as a parser option here, but since it may break existing implementations, just warn
        # if it is not explicitly set. See: https://github.com/interagent/committee/issues/343#issuecomment-997400329
        opts = parser_options.dup

        Committee.warn_deprecated_until_6(!opts.key?(:strict_reference_validation), 'openapi_parser will default to strict reference validation ' +
        'from next version. Pass config `strict_reference_validation: true` (or false, if you must) ' +
        'to quiet this warning.')
        opts[:strict_reference_validation] ||= false
        
        openapi = OpenAPIParser.parse_with_filepath(hash, schema_path, opts)
        return Committee::Drivers::OpenAPI3::Driver.new.parse(openapi)
      end

      driver = if hash['swagger'] == '2.0'
                 Committee::Drivers::OpenAPI2::Driver.new
               else
                 Committee::Drivers::HyperSchema::Driver.new
               end

      # TODO: in the future, pass `opts` here and allow optionality in other drivers?
      driver.parse(hash)
    end
  end
end

require_relative "drivers/driver"
require_relative "drivers/schema"
require_relative "drivers/hyper_schema"
require_relative "drivers/open_api_2"
require_relative "drivers/open_api_3"
