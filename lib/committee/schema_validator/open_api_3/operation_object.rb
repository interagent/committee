module Committee
  class SchemaValidator::OpenAPI3::OperationObject
    # TODO: anyOf support

    attr_reader :path_params

    attr_reader :request_operation

    # @!attribute [r] request_operation
    #   @return [OpenAPIParser::RequestOperation]

    # @param oas_parser_endpoint [OasParser::Endpoint]
    # # @param request_operation [OpenAPIParser::RequestOperation]
    def initialize(oas_parser_endpoint, path_params, request_operation)
      @oas_parser_endpoint = oas_parser_endpoint
      @path_params = path_params
      @request_operation = request_operation
    end

    def coerce_path_parameter(query_hash, validator_option)
      Committee::SchemaValidator::OpenAPI3::StringParamsCoercer.
          new(validator_option, false).
          coerce_parameter_object(query_hash, path_parameters)
    end

    def coerce_query_parameter(query_hash, validator_option)
      Committee::SchemaValidator::OpenAPI3::StringParamsCoercer.
          new(validator_option, false).
          coerce_parameter_object(query_hash, query_parameters)
    end

    def coerce_parameter(params, validator_option)
      # FIXME
      # check_parameter_type doesn't support datetime check so first, we should string, and after validate we convert datetime.
      coerce_date_times = validator_option.coerce_date_times
      return unless coerce_date_times

      # TODO: check open_api_3_ allow path and query parameter same name
      coercer = Committee::SchemaValidator::OpenAPI3::StringParamsCoercer.new(validator_option, coerce_date_times)
      coercer.coerce_parameter_object(params, path_parameters.merge(query_parameters))
      coercer.coerce_request_body_object(params, request_body_properties)
    end

    def validate_request_params(params)
      err = case oas_parser_endpoint.method
            when 'get'
              validate_get_request_params(params)
            when 'post'
              validate_post_request_params(params)
            when 'put'
              validate_post_request_params(params)
            when 'patch'
              validate_post_request_params(params)
              #when 'delete'
              # TODO: delete validation support
            else
              raise "OpenAPI3 not support #{oas_parser_endpoint.method} method"
            end
      raise err if err
    end

    def validate_response_params(status_code, content_type, params)
      return request_operation.validate_response_body(status_code, content_type, params)
    rescue => e
      raise Committee::InvalidRequest.new(e.message)
    end

    private

    def validate_get_request_params(params)
      # TODO: check path parameter
      
      parameter_object_hash = oas_parser_endpoint.
          parameters.
          map { |parameter| parameter.in == "query" ? [parameter.name, parameter] : nil }.
          compact.
          to_h

      no_exist_required_params = parameter_object_hash.select{ |_, v| v.required }.keys - params.keys
      return InvalidRequest.new("required parameters #{no_exist_required_params.to_a.join(",")} not exist") unless no_exist_required_params.empty?

      params.each do |name, value|
        parameter_object = parameter_object_hash[name]
        next unless parameter_object

        err = check_parameter_type(name, value, parameter_object)
        return err if err
      end

      nil
    end

    # @return [OasParser::Endpoint]
    attr_reader :oas_parser_endpoint

    def validate_post_request_params(params)
      # TODO: performance problem
      # TODO: support other content type
        return request_operation.validate_request_body('application/json', params)
    rescue => e
      raise Committee::InvalidRequest.new(e.message)
    end

    def check_parameter_type(name, value, parameter)
      return unless parameter # not definition in OpenAPI3

      if value.nil?
        return if parameter.raw["nullable"]

        return InvalidRequest.new("invalid parameter type #{name} #{value} #{value.class} #{parameter.type}")
      end

      case parameter.type
      when "string"
        return string_check(name, value, parameter) if value.is_a?(String)
      when "integer"
        return integer_check(name, value, parameter) if value.is_a?(Integer)
      when "boolean"
        return if value.is_a?(TrueClass)
        return if value.is_a?(FalseClass)
      when "number"
        return integer_check(name, value, parameter) if value.is_a?(Integer)
        return number_check(name, value, parameter) if value.is_a?(Numeric)
      when "object"
        return validate_object(name, value, parameter) if value.is_a?(Hash)
      when "array"
        return validate_array(name, value, parameter) if value.is_a?(Array)
      else
        # TODO: unknown type support
      end

      InvalidRequest.new("invalid parameter type #{name} #{value} #{value.class} #{parameter.type}")
    end

    def number_check(name, value, parameter)
      check_enum_include(name, value, parameter)
    end

    def integer_check(name, value, parameter)
      check_enum_include(name, value, parameter)
    end

    def string_check(name, value, parameter)
      check_enum_include(name, value, parameter)
    end

    def check_enum_include(name, value, parameter)
      return unless parameter.enum
      return if parameter.enum.include?(value)

      InvalidRequest.new("Invalid parameter #{name} #{value} isn't in enum")
    end

    # @param [OasParser::Parameter] parameter parameter.type = array
    # @param [Array<Object>] values
    def validate_array(object_name, values, parameter)
      is_any_of = parameter.items['anyOf']

      items = if is_any_of
                parameter.items['anyOf'].map{ |item| OasParser::Parameter.new(parameter, item) }
              else
                [OasParser::Parameter.new(parameter, parameter.items)] # TODO: multi pattern items support (allOf)
              end

      values.each do |v|
        if is_any_of
          next if items.any? { |item| check_parameter_type(object_name, v, item).nil? }
          return InvalidRequest.new("Invalid parameter #{v} isn't any of #{items}")
        else
          err = check_parameter_type(object_name, v, items.first)
          return err if err
        end
      end

      nil
    end

    def validate_object(_object_name, values, parameter)
      properties_hash = parameter.properties.map{ |po| [po.name, po]}.to_h
      required_set = parameter.raw['required'] ? parameter.raw['required'].to_set : Set.new

      values.each do |name, value|
        parameter = properties_hash[name]
        err = check_parameter_type(name, value, parameter)
        return err if err

        required_set.delete(name)
      end

      return InvalidRequest.new("required parameters #{required_set.to_a.join(",")} not exist") unless required_set.empty?
      nil
    end

    def request_body_properties
      # TODO: use original format
      return @request_body_properties  if defined?(@request_body_properties )

      requset_body = oas_parser_endpoint.request_body
      @request_body_properties = requset_body ? requset_body.properties_for_format('application/json').map{ |po| [po.name, po]}.to_h : {}
    end

    def query_parameters
      @query_parameters ||= oas_parser_endpoint.query_parameters.map{ |parameter| [parameter.name, parameter] }.to_h
    end

    def path_parameters
      @path_parameters ||= oas_parser_endpoint.path_parameters.map{ |parameter| [parameter.name, parameter] }.to_h
    end
  end
end
