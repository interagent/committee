# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'committee/version'

Gem::Specification.new do |s|
  s.name          = "committee"
  s.version       = Committee::VERSION

  s.summary       = "A collection of Rack middleware to support JSON Schema."

  s.authors       = ["Brandur", "geemus (Wesley Beary)", "ota42y"]
  s.email         = ["brandur@mutelight.org", "geemus+github@gmail.com", "ota42y@gmail.com"]
  s.homepage      = "https://github.com/interagent/committee"
  s.license       = "MIT"

  s.executables << "committee-stub"
  s.files = Dir["{bin,lib,test}/**/*.rb"]

  s.required_ruby_version = ">= 2.7.0"

  s.add_dependency "json_schema", "~> 0.14", ">= 0.14.3"

  s.add_dependency "rack", ">= 1.5", "< 3.2"
  s.add_dependency "openapi_parser", "~> 2.0"

  s.add_development_dependency "minitest", "~> 5.3"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "rake", "~> 13.1"
  s.add_development_dependency "debug"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "rubocop-performance"
  s.add_development_dependency "simplecov"

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/interagent/committee/issues",
    "changelog_uri" => "https://github.com/interagent/committee/blob/master/CHANGELOG.md",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/interagent/committee"
  }
end
