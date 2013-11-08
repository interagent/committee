require "minitest"
require "minitest/spec"
require 'minitest/pride'
require "minitest/autorun"

require "bundler/setup"
Bundler.require(:development)

require_relative "../lib/rack/committee"

ValidApp = {
  "archived_at"                    => "",
  "buildpack_provided_description" => "",
  "created_at"                     => "",
  "id"                             => "",
  "git_url"                        => "",
  "maintenance"                    => "",
  "name"                           => "",
  "owner"                          => {
    "email"                        => "",
    "id"                           => "",
  },
  "region"                         => {
    "id"                           => "",
    "name"                         => "",
  },
  "released_at"                    => "",
  "repo_size"                      => "",
  "slug_size"                      => "",
  "stack"                          => {
    "id"                           => "",
    "name"                         => "",
  },
  "updated_at"                     => "",
  "web_url"                        => "",
}.freeze
