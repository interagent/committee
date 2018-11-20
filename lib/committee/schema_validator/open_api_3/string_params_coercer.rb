module Committee
  class SchemaValidator::OpenAPI3::StringParamsCoercer
    def initialize(validator_option, coerce_date_times)
      @coerce_recursive = validator_option.coerce_recursive
      @coerce_date_times = coerce_date_times
    end

    def coerce_parameter_object(query_hash, parameter_hash)
      return {} unless query_hash

      query_hash.each do |k,v|
        next if v.nil?

        parameter_object = parameter_hash[k]
        next unless parameter_object

        # parameter_object.schema is hash not object... :(
        new_value, is_change = coerce_value(v, parameter_object.schema)

        query_hash[k] = new_value if is_change
      end
      query_hash
    end

    def coerce_request_body_object(params, request_body_hash)
      return {} unless params

      params.each do |k,v|
        next if v.nil?

        schema_object = request_body_hash[k]
        next unless schema_object

        # refactoring....
        new_value, is_change = coerce_value(v, schema_object.raw)

        params[k] = new_value if is_change
      end
      params
    end

    private

    def coerce_value(value, schema_hash)
      return [nil, false] unless value
      return [value, false] unless schema_hash

      case schema_hash["type"]
      when "string"
        if @coerce_date_times && schema_hash['format'] == "date-time"
          return parse_date_time(value)
        end
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
      when "array"
        if @coerce_recursive && coerce_array(value, schema_hash)
          return value, true # change original value
        end
      when "object"
        if @coerce_recursive && coerce_object(value, schema_hash)
          return value, true # change original value
        end
      else
        # nothing to do
      end

      return [nil, true] if schema_hash["nullable"] && value == ""

      [nil, false]
    end

    def coerce_array(value, schema_hash)
      return false unless schema_hash['items']
      return false unless value.is_a?(Array)

      is_coerced = false
      value.each_with_index do |d, index|
        new_value, is_changed = coerce_value(d, schema_hash['items'])
        next unless is_changed

        value[index] = new_value
        is_coerced = true
      end

      is_coerced
    end

    def coerce_object(hash, schema_hash)
      return false unless schema_hash['properties']
      return false unless hash.respond_to?(:[])

      is_coerced = false
      schema_hash['properties'].each do |k, s|
        original_val = hash[k]
        next if original_val.nil?

        new_value, is_changed = coerce_value(original_val, s)
        next unless is_changed

        hash[k] = new_value
        is_coerced = true
      end

      is_coerced
    end

    def parse_date_time(original_val)
      begin
        return DateTime.parse(original_val), true
      rescue ArgumentError => e
        raise ::Committee::InvalidResponse unless e.message =~ /invalid date/
      end

      [original_val, false]
    end
  end
end
