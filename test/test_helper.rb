if RUBY_VERSION >= '2.0.0'
  require 'simplecov'

  SimpleCov.start do
    # We do our utmost to test our executables by modularizing them into
    # testable pieces, but testing them to completion is nearly impossible as
    # far as I can tell, so include them in our tests but don't calculate
    # coverage.
    add_filter "/bin/"

    add_filter "/test/"

    # This library has a pretty modest number of lines, so let's try to stick
    # to a 100% coverage target for a while and see what happens.
    minimum_coverage 100
  end
end

require "minitest"
require "minitest/spec"
require "minitest/autorun"
require "rack/test"
require "rr"
require "pry"

require_relative "../lib/committee"

# The OpenAPI sample specification provided directly from the organization uses
# a couple custom "format" values for JSON schema, namely "int32" and "int64".
# Provide basic definitions for them here so that we don't error when trying to
# parse the sample.
JsonSchema.configure do |c|
  c.register_format 'int32', ->(data) {}
  c.register_format 'int64', ->(data) {}
end

# For our hyper-schema example.
ValidApp = {
  "maintenance" => false,
  "name"        => "example",
}.freeze

# For our OpenAPI example.
ValidPet = {
  "id"   => 123,
  "name" => "example",
  "tag"  => "tag-123",
}.freeze

def hyper_schema
  @hyper_schema ||= Committee::Drivers.load_from_json(hyper_schema_filepath)
end

def open_api_2_schema
  @open_api_2_schema ||= Committee::Drivers.load_from_file(open_api_2_filepath)
end

def open_api_3_schema
  @open_api_3_schema ||= Committee::Drivers.load_from_data(open_api_3_data)
end

# Don't cache this because we'll often manipulate the created hash in tests.
def hyper_schema_data
  JSON.parse(File.read(hyper_schema_filepath))
end

# Don't cache this because we'll often manipulate the created hash in tests.
def open_api_2_data
  JSON.parse(File.read(open_api_2_filepath))
end

def open_api_3_data
  YAML.load_file(open_api_3_filepath)
end

def hyper_schema_filepath
  "./test/data/hyperschema/paas.json"
end

def open_api_2_filepath
  "./test/data/openapi2/petstore-expanded.json"
end

def open_api_3_filepath
  "./test/data/openapi3/normal.yml"
end
