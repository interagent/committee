Gem::Specification.new do |s|
  s.name          = "committee"
  s.version       = "1.2.0"

  s.summary       = "A collection of Rack middleware to support JSON Schema."

  s.authors       = ["Brandur", "geemus (Wesley Beary)"]
  s.email         = ["brandur@mutelight.org", "geemus+github@gmail.com"]
  s.homepage      = "https://github.com/interagent/committee"
  s.license       = "MIT"

  s.executables   << "committee-stub"
  s.files         = Dir["{bin,lib,test}/**/*.rb"]

  s.add_dependency "json_schema", "~> 0.1"
  s.add_dependency "multi_json", "> 0.0"
  s.add_dependency "rack", "> 0.0"
end
