Gem::Specification.new do |s|
  s.name          = "committee"
  s.version       = "2.1.0"

  s.summary       = "A collection of Rack middleware to support JSON Schema."

  s.authors       = ["Brandur", "geemus (Wesley Beary)"]
  s.email         = ["brandur@mutelight.org", "geemus+github@gmail.com"]
  s.homepage      = "https://github.com/interagent/committee"
  s.license       = "MIT"

  s.executables   << "committee-stub"
  s.files         = Dir["{bin,lib,test}/**/*.rb"]

  s.add_dependency "json_schema", "~> 0.14", ">= 0.14.3"

  # Rack 2.0+ requires Ruby >= 2.2.2 which is problematic for the test suite on
  # older Ruby versions. Check Ruby the version here and put a maximum
  # constraint on Rack if necessary.
  if RUBY_VERSION >= '2.2.2'
    s.add_dependency "rack", ">= 1.5"
  else
    s.add_dependency "rack", ">= 1.5", "< 2.0"
  end

  s.add_development_dependency "minitest", "~> 5.3"
  s.add_development_dependency "minitest-line"
  s.add_development_dependency "rack-test", "~> 0.6"
  s.add_development_dependency "rake", "~> 10.3"
  s.add_development_dependency "rr", "~> 1.1"

  # Gate gems that have trouble installing on older versions of Ruby.
  if RUBY_VERSION >= '2.0.0'
    s.add_development_dependency "pry"
    s.add_development_dependency "pry-byebug"
    s.add_development_dependency "simplecov"
  end
end
