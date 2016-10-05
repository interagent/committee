require "minitest"
require "minitest/spec"
require "minitest/autorun"
#require "pry-rescue/minitest"
require "rack/test"
require "rr"

require_relative "../lib/committee"

ValidApp = {
  "maintenance" => false,
  "name"        => "example",
}.freeze

def hyper_schema_data
  @hyper_schema_data ||=
    JSON.parse(File.read("./test/data/hyperschema/heroku.json"))
end

def open_api_2_data
  @open_api_2_data ||=
    JSON.parse(File.read("./test/data/openapi2/petstore-expanded.json"))
end
