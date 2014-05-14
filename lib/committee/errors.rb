module Committee
  class Error < StandardError
  end

  class BadRequest < Error
  end

  class InvalidRequest < Error
  end

  class InvalidResponse < Error
  end

  class ReferenceNotFound < Error
  end
end
