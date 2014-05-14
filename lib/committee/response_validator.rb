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

      @error = InvalidParams.new

      (data_keys - schema_keys).each do |extra_param|
        @error.add(:extra, extra_param)
      end

      (schema_keys - data_keys).each do |missing_param|
        @error.add(:missing, missing_param)
      end

      check_data(@type_schema, data, [])

      if @error.count > 0
        raise @error
      end
    end

    def check_data(schema, data, path)
      schema["properties"].each do |key, value|
        next if @error.on(key) == :missing

        if value["properties"]
          check_data(value, data[key], path + [key])
        elsif value["type"] == ["array"]
          definition = @schema.find(value["items"]["$ref"])
          data[key].each do |datum|
            if !check_type(definition["type"], datum, path + [key])
              @error.add(:bad_type, key)
            elsif definition["type"] == ["object"]
              check_data(definition, datum, path + [key])
            elsif definition["type"].include?("null") && datum.nil?
              next
            elsif !check_format(definition["format"], datum, path + [key])
              @error.add(:bad_format, key)
            elsif !check_pattern(definition["pattern"], datum, path + [key])
              @error.add(:bad_pattern, key)
            end
          end

        else
          definition = @schema.find(value["$ref"])
          if !check_type(definition["type"], data[key], path + [key])
            @error.add(:bad_type, key)
          elsif definition["type"].include?("null") && data[key].nil?
            next
          elsif !check_format(definition["format"], data[key], path + [key])
            @error.add(:bad_format, key)
          elsif !check_pattern(definition["pattern"], data[key], path + [key])
            @error.add(:bad_pattern, key)
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
