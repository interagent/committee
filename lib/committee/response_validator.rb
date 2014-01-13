module Committee
  class ResponseValidator
    def initialize(data, schema, link_schema, type_schema)
      @data = data
      @schema = schema
      @link_schema = link_schema
      @type_schema = type_schema
    end

    def call
      data = if @link_schema["title"] == "List"
        if !@data.is_a?(Array)
          raise InvalidResponse, "List endpoints must return an array of objects."
        end
        # only consider the first object during the validation from here on
        @data[0]
      else
        @data
      end

      data_keys = build_data_keys(data)
      schema_keys = build_schema_keys

      extra = data_keys - schema_keys
      missing = schema_keys - data_keys

      errors = []

      if extra.count > 0
        errors << "Extra keys in response: #{extra.join(', ')}."
      end

      if missing.count > 0
        errors << "Missing keys in response: #{missing.join(', ')}."
      end

      unless errors.empty?
        raise InvalidResponse, ["`#{@link_schema['method']} #{@link_schema['href']}` deviates from schema.", *errors].join(' ')
      end

      check_data!(@type_schema, data, [])
    end

    def check_data!(schema, data, path)
      schema["properties"].each do |key, value|
        if value["properties"]
          check_data!(value, data[key], path + [key])
        else
          definition = @schema.find(value["$ref"])
          check_type!(definition["type"], data[key], path + [key])
          unless definition["type"].include?("null") && data[key].nil?
            check_format!(definition["format"], data[key], path + [key])
            check_pattern!(definition["pattern"], data[key], path + [key])
          end
        end
      end
    end

    def check_format!(format, value, path)
      return if !format
      valid = case format
      when "date-time"
        value =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})(Z|[+-](\d{2})\:(\d{2}))$/
      when "email"
        value =~ /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/i
      when "uuid"
        value =~ /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/
      else
        true
      end
      unless valid
        raise InvalidResponse,
          %{Invalid format at "#{path.join(":")}": expected "#{value}" to be "#{format}".}
      end
    end

    def check_pattern!(pattern, value, path)
      if pattern && !(value =~ pattern)
        raise InvalidResponse,
          %{Invalid pattern at "#{path.join(":")}": expected #{value} to match "#{pattern}".}
      end
    end

    def check_type!(types, value, path)
      type = case value
      when NilClass
        "null"
      when TrueClass, FalseClass
        "boolean"
      when Fixnum
        "integer"
      when String
        "string"
      else
        "unknown"
      end
      unless types.include?(type)
        raise InvalidResponse,
          %{Invalid type at "#{path.join(":")}": expected #{value} to be #{types} (was: #{type}).}
      end
    end

    private

    def build_data_keys(data)
      keys = []
      data.each do |key, value|
        if value.is_a?(Hash)
          keys += value.keys.map { |k| "#{key}:#{k}" }
        else
          keys << key
        end
      end
      keys
    end

    def build_schema_keys
      keys = []
      @type_schema["properties"].each do |key, info|
        data = if info["properties"]
          info
        elsif info["$ref"]
          @schema.find(info["$ref"])
        end
        if data["properties"]
          keys += data["properties"].keys.map { |k| "#{key}:#{k}" }
        else
          keys << key
        end
      end
      keys
    end
  end
end
