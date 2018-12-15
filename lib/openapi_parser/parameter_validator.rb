class OpenAPIParser::ParameterValidator
  class << self
    # @param [Hash{String => Parameter}] parameters_hash
    # @param [Hash] params
    # @param [String] object_reference
    def validate_parameter(parameters_hash, params, object_reference)
      no_exist_required_key = []
      parameters_hash.each do |k, v|
        if (data = params[k])
          v.validate_params(data)
        elsif v.required
          no_exist_required_key << k
        end
      end

      raise OpenAPIParser::NotExistRequiredKey.new(no_exist_required_key, object_reference) unless no_exist_required_key.empty?
    end
  end
end
