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

    private

    attr_reader :oas_parser_endpoint

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
