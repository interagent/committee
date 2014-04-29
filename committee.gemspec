Gem::Specification.new do |s|
  s.name          = "committee"
  s.version       = "0.4.10"

  s.summary       = "A collection of Rack middleware to support JSON Schema."

  s.authors       = ["Brandur", "geemus (Wesley Beary)"]
  s.email         = ["brandur@mutelight.org", "geemus+github@gmail.com"]
  s.homepage      = "https://github.com/heroku/committee"
  s.license       = "MIT"

  s.executables   << "committee-stub"
  s.files         = Dir["{bin,lib,test}/**/*.rb"]

  s.add_dependency "multi_json", "> 0.0"
  s.add_dependency "rack", "> 0.0"

  s.add_development_dependency "rack-test"
end
