# We want to use class name for DSL in class definition so we should define first...

module OpenAPIParser::Schemas
  class Base; end
  class Discriminator < Base; end
  class OpenAPI < Base; end
  class Operation < Base; end
  class Parameter < Base; end
  class PathItem < Base; end
  class Paths < Base; end
  class Reference < Base; end
  class RequestBody < Base; end
  class Responses < Base; end
  class Response < Base; end
  class MediaType < Base; end
  class Schema < Base; end
  class Components < Base; end
  class Header < Base; end
end
