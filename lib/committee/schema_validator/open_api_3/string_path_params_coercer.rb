module Committee
  class SchemaValidator::OpenAPI3::StringPathParamsCoercer
    def initialize(query_hash, operation_object, validator_option)
      @query_hash = query_hash
      @operation_object = operation_object
      @coerce_recursive = validator_option.coerce_recursive
    end

    def call!
      return {} unless @query_hash

      coerce_path_parameters(@query_hash, @operation_object)
    end

    private

    def coerce_path_parameters(query_hash, operation_object)
      query_hash.each do |k,v|
        next if v.nil?
        new_value, is_change = operation_object.coerce_path_parameter_object(k,v)

        query_hash[k] = new_value if is_change
      end
      query_hash
    end
  end
end
