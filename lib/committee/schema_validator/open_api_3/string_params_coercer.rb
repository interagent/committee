module Committee
  class SchemaValidator::OpenAPI3::StringParamsCoercer
    def initialize(validator_option)
      @coerce_recursive = validator_option.coerce_recursive
    end

    def coerce_parameter_object(query_hash, parameter_hash)
      return {} unless query_hash

      query_hash.each do |k,v|
        next if v.nil?

        parameter_object = parameter_hash[k]
        next unless parameter_object

        new_value, is_change = coerce_value(v, parameter_object)

        query_hash[k] = new_value if is_change
      end
      query_hash
    end

    private

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
