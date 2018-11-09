module Committee
  class SchemaValidator::OpenAPI3::OperationObject
    # @param oas_parser_endpoint [OasParser::Endpoint]
    def initialize(oas_parser_endpoint)
      @oas_parser_endpoint = oas_parser_endpoint
    end

    def coerce_query_parameter_object(name, value)
      query_parameter_object = query_parameters[name]
      return [nil, false] unless query_parameter_object

      coerce_value(value, query_parameter_object)
    end

    def validate(params)
      case oas_parser_endpoint.method
      when 'get'
        # TODO: get validation support
      when 'post'
        validate_post_params(params)
      else
        raise "OpenAPI3 not support #{oas_parser_endpoint.method} method"
      end
    end

    private

    attr_reader :oas_parser_endpoint

    def validate_post_params(params)
      params.each do |name, value|
        parameter = request_body_properties[name]
        check_parameter_type(name, value, parameter)
      end
    end

    def check_parameter_type(name, value, parameter)
      return unless parameter # not definition in OpenAPI3

      if value.nil?
        return if parameter.raw['nullable']

        raise InvalidRequest, "invalid parameter type #{name} #{value} #{value.class} #{parameter.type}"
      end

      # TODO: check array parameter
      case parameter.type
      when "string"
        return if value.is_a?(String)
      when "integer"
        return if value.is_a?(Integer)
      when "boolean"
        return if value.is_a?(TrueClass)
        return if value.is_a?(FalseClass)
      when "number"
        return if value.is_a?(Integer)
        return if value.is_a?(Numeric)
      when "object"
        return if value.is_a?(Hash) && validate_object(name, value, parameter.properties)
      end

      raise InvalidRequest, "invalid parameter type #{name} #{value} #{value.class} #{parameter.type}"
    end

    def validate_object(_object_name, values, object_properties)
      properties_hash = object_properties.map{ |po| [po.name, po]}.to_h

      values.each do |name, value|
        parameter = properties_hash[name]
        check_parameter_type(name, value, parameter)
      end

      true
    end

    def request_body_properties
      # TODO: use original format
      @request_body_properties ||= oas_parser_endpoint.request_body.properties_for_format('application/json').map{ |po| [po.name, po]}.to_h
    end

    def query_parameters
      @query_parameters ||= oas_parser_endpoint.query_parameters.map{ |parameter| [parameter.name, parameter] }.to_h
    end

    def coerce_value(value, query_parameter_object)
      return [nil, false] unless value

      schema = query_parameter_object.schema
      return [value, false] unless schema

      case schema["type"]
      when "integer"
        begin
          return Integer(value), true
        rescue ArgumentError => e
          raise e unless e.message =~ /invalid value for Integer/
        end
      when "boolean"
        if value == "true" || value == "1"
          return true, true
        end
        if value == "false" || value == "0"
          return false, true
        end
      when "number"
        begin
          return Float(value), true
        rescue ArgumentError => e
          raise e unless e.message =~ /invalid value for Float/
        end
      else
        # nothing to do
      end

      return [nil, true] if schema["nullable"] && value == ""

      [nil, false]
    end
  end
end
