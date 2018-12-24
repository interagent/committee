require 'bundler/setup'
require 'yaml'
require 'pry'
require 'rspec-parameterized'
require 'simplecov'

SimpleCov.start 'rails'

require 'openapi_parser'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def normal_schema
  YAML.load_file('./spec/data/normal.yml')
end

def petstore_schema
  YAML.load_file('./spec/data/petstore-expanded.yaml')
end
