# frozen_string_literal: true

module Committee
  class Error < StandardError
  end

  class BadRequest < Error
  end

  class InvalidRequest < Error
  end

  class InvalidResponse < Error
  end

  class NotFound < Error
  end

  class ReferenceNotFound < Error
  end

  class OpenAPI3Unsupported < Error
  end
end
