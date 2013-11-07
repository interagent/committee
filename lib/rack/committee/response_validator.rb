module Rack::Committee
  class ResponseValidator
    def initialize(data, type_schema)
      @data = data
      @type_schema = type_schema
    end

    def call
      data_keys = build_data_keys
      schema_keys = build_schema_keys

      missing = schema_keys - data_keys
      extra = data_keys - schema_keys

      if missing.count > 0
        raise ResponseError.new("Missing keys in response: #{extra.join(', ')}.")
      end

      if extra.count > 0
        raise ResponseError.new("Extra keys in response: #{extra.join(', ')}.")
      end
    end

    private

    def build_data_keys
      keys = []
      @data.each do |key, value|
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
        if info["properties"]
          keys += info["properties"].keys.map { |k| "#{key}:#{k}" }
        else
          keys << key
        end
      end
      keys
    end
  end
end
