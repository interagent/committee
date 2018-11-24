lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openapi_parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'openapi_parser'
  spec.version       = OpenapiParser::VERSION
  spec.authors       = ['ota42y']
  spec.email         = ['ota42y@gmail.com']

  spec.summary       = 'OpenAPI3 parser'
  spec.description   = 'parser for OpenAPI 3.0 or later'
  spec.homepage      = 'https://ota42y.com'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'fincop'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
