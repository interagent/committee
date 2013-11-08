module Rack::Committee
  class ParamValidator
    def initialize(params, link_schema)
      @params = params
      @link_schema = link_schema
    end

    def call
      detect_missing!
      detect_extra!
    end

    private

    def detect_extra!
      extra = @params.keys - all_keys
      if extra.count > 0
        raise InvalidParams.new("Unknown params: #{missing.join(', ')}.")
      end
    end

    def detect_missing!
      missing = required_keys - @params.keys
      if missing.count > 0
        raise InvalidParams.new("Require params: #{missing.join(', ')}.")
      end
    end

    def all_keys
      properties = @link_schema["schema"] && @link_schema["schema"]["properties"]
      properties && properties.keys || []
    end

    def required_keys
      (@link_schema["schema"] && @link_schema["schema"]["required"]) || []
    end
  end
end
