Gem::Specification.new do |s|
  s.name          = "committee"
  s.version       = "1.11.1"

  s.summary       = "A collection of Rack middleware to support JSON Schema."

  s.authors       = ["Brandur", "geemus (Wesley Beary)"]
  s.email         = ["brandur@mutelight.org", "geemus+github@gmail.com"]
  s.homepage      = "https://github.com/interagent/committee"
  s.license       = "MIT"

  s.executables   << "committee-stub"
  s.files         = Dir["{bin,lib,test}/**/*.rb"]

  s.add_dependency "json_schema", "~> 0.6", ">= 0.6.1"
  s.add_dependency "rack", "~> 1.5"

  s.add_development_dependency "minitest", "~> 5.3"
  s.add_development_dependency "rack-test", "~> 0.6"
  s.add_development_dependency "rake", "~> 10.3"
  s.add_development_dependency "rr", "~> 1.1"
end
