module Committee
  class Error < StandardError
  end

  class BadRequest < Error
  end

  class InvalidPattern < Error
  end

  class InvalidFormat < Error
  end

  class InvalidType < Error
  end

  class InvalidParams < Error
  end

  class InvalidResponse < Error
  end

  class ReferenceNotFound < Error
  end
end
