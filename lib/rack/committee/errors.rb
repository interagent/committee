module Rack::Committee
  class BadRequest < StandardError
  end

  class InvalidParams < StandardError
  end

  class ResponseError < StandardError
  end
end
