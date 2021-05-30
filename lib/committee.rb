# frozen_string_literal: true

require "json"
require "yaml"
require "json_schema"
require "rack"
require 'openapi_parser'

module Committee
  def self.debug?
    ENV["COMMITTEE_DEBUG"]
  end

  def self.log_debug(message)
    $stderr.puts(message) if debug?
  end

  def self.warn_deprecated(message)
    warn("[DEPRECATION] #{message}")
  end
end

require_relative "committee/utils"
require_relative "committee/drivers"
require_relative "committee/errors"
require_relative "committee/middleware"
require_relative "committee/request_unpacker"
require_relative "committee/schema_validator"
require_relative "committee/validation_error"

require_relative "committee/bin/committee_stub"
require_relative "committee/test/methods"
require_relative "committee/test/schema_coverage"
