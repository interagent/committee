require "minitest"
require "minitest/spec"
require "minitest/autorun"
require "rack/test"
require "rr"

require_relative "../lib/committee"

ValidApp = {
  "maintenance" => false,
  "name"        => "example",
}.freeze
