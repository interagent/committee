require "minitest"
require "minitest/spec"
require 'minitest/pride'
require "minitest/autorun"

require "bundler/setup"
Bundler.require(:development)

require_relative "../lib/committee"

ValidApp = {
  "archived_at"                    => "2012-01-01T12:00:00Z",
  "buildpack_provided_description" => "Ruby/Rack",
  "created_at"                     => "2012-01-01T12:00:00Z",
  "git_url"                        => "git@heroku.com/example.git",
  "id"                             => "01234567-89ab-cdef-0123-456789abcdef",
  "maintenance"                    => false,
  "name"                           => "example",
  "owner"                          => {
    "email"                        => "username@example.com",
    "id"                           => "01234567-89ab-cdef-0123-456789abcdef"
  },
  "region"                         => {
    "id"                           => "01234567-89ab-cdef-0123-456789abcdef",
    "name"                         => "us"
  },
  "released_at"                    => "2012-01-01T12:00:00Z",
  "repo_size"                      => 0,
  "slug_size"                      => 0,
  "stack"                          => {
    "id"                           => "01234567-89ab-cdef-0123-456789abcdef",
    "name"                         => "cedar"
  },
  "updated_at"                     => "2012-01-01T12:00:00Z",
  "web_url"                        => "http://example.herokuapp.com"
}.freeze
