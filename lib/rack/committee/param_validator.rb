module Rack::Committee
  class ParamValidator
    def initialize(params, schema, link_schema)
      @params = params
      @schema = schema
      @link_schema = link_schema
    end

    def call
      detect_missing!
      detect_extra!
      check_data!
    end

    private

    def all_keys
      properties = @link_schema["schema"] && @link_schema["schema"]["properties"]
      properties && properties.keys || []
    end

    def check_data!
      return if !@link_schema["schema"] || !@link_schema["schema"]["properties"]

      @link_schema["schema"]["properties"].each do |key, value|
        # don't try to check this unless it was actually specificed
        next unless @params.key?(key)

        match = false
        definitions = find_definitions(value["$ref"])

        # try to match data against any possible definition
        definitions.each do |definition|
          if check_type(definition["type"], @params[key], key) &&
            check_format(definition["format"], @params[key], key) &&
            check_pattern(definition["pattern"], @params[key], key)
            match = true
            next
          end
        end

        # if nothing was matched, throw error according to first definition
        if !match && definition = definitions.first
          check_type!(definition["type"], @params[key], key)
          check_format!(definition["format"], @params[key], key)
          check_pattern!(definition["pattern"], @params[key], key)
        end
      end
    end

    def check_format(format, value, key)
      case format
      when "date-time"
        value =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})(Z|[+-](\d{2})\:(\d{2}))$/
      when "email"
        value =~ /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/i
      when "uuid"
        value =~ /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/
      else
        true
      end
    end

    def check_format!(format, value, key)
      unless check_format(format, value, key)
        raise InvalidParams,
          %{Invalid format for key "#{key}": expected "#{value}" to be "#{format}".}
      end
    end

    def check_pattern(pattern, value, key)
      !pattern || value =~ pattern
    end

    def check_pattern!(pattern, value, key)
      unless check_pattern(pattern, value, key)
        raise InvalidParams,
          %{Invalid pattern for key "#{key}": expected #{value} to match "#{pattern}".}
      end
    end

    def check_type(types, value, key)
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
      types.include?(type)
    end

    def check_type!(types, value, key)
      unless check_type(types, value, key)
        raise InvalidParams,
          %{Invalid type for key "#{key}": expected #{value} to be #{types}.}
      end
    end

    def detect_extra!
      extra = @params.keys - all_keys
      if extra.count > 0
        raise InvalidParams.new("Unknown params: #{extra.join(', ')}.")
      end
    end

    def detect_missing!
      missing = required_keys - @params.keys
      if missing.count > 0
        raise InvalidParams.new("Require params: #{missing.join(', ')}.")
      end
    end

    def find_definitions(ref)
      definition = @schema.find(ref)
      if definition["anyOf"]
        definition["anyOf"].map { |r| @schema.find(r["$ref"]) }
      else
        [definition]
      end
    end

    def required_keys
      (@link_schema["schema"] && @link_schema["schema"]["required"]) || []
    end
  end
end
