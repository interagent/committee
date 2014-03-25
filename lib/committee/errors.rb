module Committee
  class BadRequest < StandardError
  end

  class InvalidPattern < StandardError
  end

  class InvalidFormat < StandardError
  end

  class InvalidType < StandardError
  end

  class InvalidParams < StandardError
  end

  class InvalidResponse < StandardError
  end

  class ReferenceNotFound < StandardError
  end
end
