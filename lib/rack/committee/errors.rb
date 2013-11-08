module Rack::Committee
  class BadRequest < StandardError
  end

  class InvalidParams < StandardError
  end

  class InvalidResponse < StandardError
  end

  class ReferenceNotFound < StandardError
  end
end
