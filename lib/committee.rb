require "json"
require "json_schema"
require "rack"

require_relative "committee/errors"
require_relative "committee/query_params_coercer"
require_relative "committee/request_unpacker"
require_relative "committee/request_validator"
require_relative "committee/response_generator"
require_relative "committee/response_validator"
require_relative "committee/router"
require_relative "committee/validation_error"

require_relative "committee/drivers"
require_relative "committee/drivers/hyper_schema"
require_relative "committee/drivers/open_api_2"

require_relative "committee/middleware/base"
require_relative "committee/middleware/request_validation"
require_relative "committee/middleware/response_validation"
require_relative "committee/middleware/stub"

require_relative "committee/test/methods"

module Committee
  def self.warn_deprecated(message)
    if !$VERBOSE.nil?
      $stderr.puts(message)
    end
  end
end
