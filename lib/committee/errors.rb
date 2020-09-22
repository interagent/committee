# frozen_string_literal: true

module Committee
  class Error < StandardError
  end

  class BadRequest < Error
  end

  class InvalidRequest < Error
    attr_reader :original_error

    def initialize(error_message=nil, original_error: nil)
      @original_error = original_error
      super(error_message)
    end
  end

  class InvalidResponse < Error
    attr_reader :original_error

    def initialize(error_message=nil, original_error: nil)
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
end
