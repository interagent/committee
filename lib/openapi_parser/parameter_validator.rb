class OpenAPIParser::ParameterValidator
  class << self
    # @param [Hash{String => Parameter}] parameters_hash
    # @param [Hash] params
    # @param [String] object_reference
    def validate_parameter(parameters_hash, params, object_reference, coerce_value)
      no_exist_required_key = []
      parameters_hash.each do |k, v|
        if (data = params[k])
          coerced = v.validate_params(data, coerce_value)
          params[k] = coerced if coerce_value
        elsif v.required
          no_exist_required_key << k
        end
      end

      raise OpenAPIParser::NotExistRequiredKey.new(no_exist_required_key, object_reference) unless no_exist_required_key.empty?

      params
    end
  end
end
