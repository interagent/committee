module OpenAPIParser::ParameterValidatable
  # @param [Hash] path_params path parameters
  # @param [OpenAPIParser::SchemaValidator::Options] options request validator options
  def validate_path_params(path_params, options)
    OpenAPIParser::ParameterValidator.validate_parameter(path_parameter_hash, path_params, object_reference, options)
  end

  # @param [Hash] params parameter hash
  # @param [Hash] headers headers hash
  # @param [OpenAPIParser::SchemaValidator::Options] options request validator options
  def validate_request_parameter(params, headers, options)
    validate_header_parameter(headers, object_reference, options) if options.validate_header
    validate_query_parameter(params, object_reference, options)
  end

  private

    # @param [Hash] params query parameter hash
    # @param [String] object_reference
    # @param [OpenAPIParser::SchemaValidator::Options] options request validator options
    def validate_query_parameter(params, object_reference, options)
      OpenAPIParser::ParameterValidator.validate_parameter(query_parameter_hash, params, object_reference, options)
    end

    # @param [Hash] headers header hash
    # @param [String] object_reference
    # @param [OpenAPIParser::SchemaValidator::Options] options request validator options
    def validate_header_parameter(headers, object_reference, options)
      OpenAPIParser::ParameterValidator.validate_parameter(header_parameter_hash, headers, object_reference, options)
    end

    def header_parameter_hash
      divided_parameter_hash['header'] || []
    end

    def path_parameter_hash
      divided_parameter_hash['path'] || []
    end

    def query_parameter_hash
      divided_parameter_hash['query'] || []
    end

    # @return [Hash{String => Hash{String => Parameter}}] hash[in][name] => Parameter
    def divided_parameter_hash
      @divided_parameter_hash ||=
        (parameters || []).
          group_by(&:in).
          map { |in_type, params| # rubocop:disable Style/BlockDelimiters
          [
            in_type,
            params.map { |param| [param.name, param] }.to_h,
          ]
        }.to_h
    end
end
