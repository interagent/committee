Gem::Specification.new do |s|
  s.name          = "rack-committee"
  s.version       = "0.1"

  s.author        = "Brandur"
  s.email         = "brandur@mutelight.org"
  s.homepage      = "https://github.com/brandur/rack-committee"
  s.license       = "MIT"

  s.files         = Dir["{lib,test}/**/*.rb"]

  s.add_dependency "multi_json", "> 0.0"
  s.add_dependency "rack", "> 0.0"

  s.add_development_dependency "rack-test"
end
