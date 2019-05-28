class OpenAPIParser::ParameterValidator
  class << self
    # @param [Hash{String => Parameter}] parameters_hash
    # @param [Hash] params
    # @param [String] object_reference
    # @param [OpenAPIParser::SchemaValidator::Options] options
    # @param [Boolean] is_header is header or not (ignore params key case)
    def validate_parameter(parameters_hash, params, object_reference, options, is_header = false)
      no_exist_required_key = []

      params_key_converted = params.keys.map { |k| [convert_key(k, is_header), k] }.to_h
      parameters_hash.each do |k, v|
        key = params_key_converted[convert_key(k, is_header)]
        if params.include?(key)
          coerced = v.validate_params(params[key], options)
          params[key] = coerced if options.coerce_value
        elsif v.required
          no_exist_required_key << k
        end
      end

      raise OpenAPIParser::NotExistRequiredKey.new(no_exist_required_key, object_reference) unless no_exist_required_key.empty?

      params
    end

    private

    def convert_key(k, is_header)
      is_header ? k&.downcase : k
    end
  end
end
