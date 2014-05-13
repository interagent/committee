module Committee
  class ResponseValidator
    include Validation

    def initialize(data, schema, link_schema, type_schema)
      @data = data
      @schema = schema
      @link_schema = link_schema
      @type_schema = type_schema
    end

    def call
      data = if @link_schema["rel"] == "instances"
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
        elsif value["type"] == ["array"]
          definition = @schema.find(value["items"]["$ref"])
          data[key].each do |datum|
            check_type!(definition["type"], datum, path + [key])
            check_data!(definition, datum, path + [key]) if definition["type"] == ["object"]
            unless definition["type"].include?("null") && datum.nil?
              check_format!(definition["format"], datum, path + [key])
              check_pattern!(definition["pattern"], datum, path + [key])
            end
          end

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
        elsif info["type"] == ["array"]
          array_schema = @schema.find(info["items"]["$ref"])
          unless array_schema["type"] == ["object"]
            array_schema
          else
            {} # satisfy data['properties'] check below
          end
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
