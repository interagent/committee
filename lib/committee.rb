require "json"
require "json_schema"
require "rack"

require_relative "committee/errors"
require_relative "committee/string_params_coercer"
require_relative "committee/parameter_coercer"
require_relative "committee/request_unpacker"
require_relative "committee/request_validator"
require_relative "committee/response_generator"
require_relative "committee/response_validator"
require_relative "committee/router"
require_relative "committee/validation_error"

require_relative "committee/drivers"
require_relative "committee/drivers/hyper_schema"
require_relative "committee/drivers/open_api_2"
require_relative "committee/drivers/open_api_3"

require_relative "committee/middleware/base"
require_relative "committee/middleware/request_validation"
require_relative "committee/middleware/response_validation"
require_relative "committee/middleware/stub"

require_relative "committee/bin/committee_stub"

require_relative "committee/test/methods"

module Committee
  def self.debug?
    ENV["COMMITTEE_DEBUG"]
  end

  def self.log_debug(message)
    $stderr.puts(message) if debug?
  end

  def self.warn_deprecated(message)
    if !$VERBOSE.nil?
      $stderr.puts(message)
    end
  end
end
