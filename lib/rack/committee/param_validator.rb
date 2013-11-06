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
      properties = @link_schema["schema"]["properties"] || []
      extra = @params.keys - properties.keys
      if extra.count > 0
        raise InvalidParams.new("Unknown params: #{missing.join(', ')}.")
      end
    end

    def detect_missing!
      required = @link_schema["schema"]["required"] || []
      missing = required - @params.keys
      if missing.count > 0
        raise InvalidParams.new("Require params: #{missing.join(', ')}.")
      end
    end
  end
end
