require "minitest"
require "minitest/spec"
require 'minitest/pride'
require "minitest/autorun"

require "bundler/setup"
Bundler.require(:development)

require_relative "../lib/rack/committee"
