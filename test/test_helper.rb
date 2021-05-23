# frozen_string_literal: true

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

require "minitest"
require "minitest/spec"
require "minitest/autorun"
require "rack/test"
require "rr"
require "pry"
require "stringio"

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
  @hyper_schema ||= Committee::Drivers.load_from_json(hyper_schema_schema_path)
end

def open_api_2_schema
  @open_api_2_schema ||= Committee::Drivers.load_from_file(open_api_2_schema_path)
end

def open_api_2_form_schema
  @open_api_2_form_schema ||= Committee::Drivers.load_from_file(open_api_2_form_schema_path)
end

def open_api_3_schema
  @open_api_3_schema ||= Committee::Drivers.load_from_file(open_api_3_schema_path)
end

def open_api_3_coverage_schema
  @open_api_3_coverage_schema ||= Committee::Drivers.load_from_file(open_api_3_coverage_schema_path)
end

# Don't cache this because we'll often manipulate the created hash in tests.
def hyper_schema_data
  JSON.parse(File.read(hyper_schema_schema_path))
end

# Don't cache this because we'll often manipulate the created hash in tests.
def open_api_2_data
  JSON.parse(File.read(open_api_2_schema_path))
end

def open_api_2_form_data
  JSON.parse(File.read(open_api_2_form_schema_path))
end

def open_api_3_data
  YAML.load_file(open_api_3_schema_path)
end

def hyper_schema_schema_path
  "./test/data/hyperschema/paas.json"
end

def open_api_2_schema_path
  "./test/data/openapi2/petstore-expanded.json"
end

def open_api_2_form_schema_path
  "./test/data/openapi2/petstore-expanded-form.json"
end

def open_api_3_schema_path
  "./test/data/openapi3/normal.yaml"
end

def open_api_3_coverage_schema_path
  "./test/data/openapi3/coverage.yaml"
end

def open_api_3_0_1_schema_path
  "./test/data/openapi3/3_0_1.yaml"
end
