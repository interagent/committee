# frozen_string_literal: true

module Committee
  class Error < StandardError
  end

  class BadRequest < Error
  end

  class InvalidRequest < Error
    attr_reader :original_error

    def initialize(error_message = nil, original_error: nil)
      @original_error = original_error
      super(error_message)
    end
  end

  class InvalidResponse < Error
    attr_reader :original_error

    def initialize(error_message = nil, original_error: nil)
      @original_error = original_error
      super(error_message)
    end
  end

  class NotFound < Error
  end

  class ReferenceNotFound < Error
  end

  class OpenAPI3Unsupported < Error
  end

  class ParameterDeserializationError < InvalidRequest
    attr_reader :parameter_name, :style, :raw_value

    def initialize(param_name, style, raw_value, message)
      @parameter_name = param_name
      @style = style
      @raw_value = raw_value
      super("Parameter '#{param_name}' (style: #{style}): #{message}")
    end
  end
end
