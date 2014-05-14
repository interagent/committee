require "minitest"
require "minitest/spec"
require "minitest/autorun"
require "rr"

require "bundler/setup"
Bundler.require(:development)

require_relative "../lib/committee"

ValidApp = {
  "maintenance" => false,
  "name"        => "example",
}.freeze
