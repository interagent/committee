# frozen_string_literal: true

require "json"
require "yaml"
require "json_schema"
require "rack"
require 'openapi_parser'

require_relative "committee/version"

module Committee
  def self.debug?
    ENV["COMMITTEE_DEBUG"]
  end

  def self.log_debug(message)
    $stderr.puts(message) if debug?
  end

  def self.need_good_option(message)
    warn(message)
  end

  def self.warn_deprecated_until_6(cond, message)
    raise "remove deprecated!"  unless Committee::VERSION.start_with?("5")
    warn("[DEPRECATION] #{message}") if cond
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
