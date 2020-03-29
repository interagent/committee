require 'bundler/setup'
require 'yaml'
require 'pry'
require 'rspec-parameterized'
require 'simplecov'

SimpleCov.start do
  add_filter 'spec'
end

SimpleCov.minimum_coverage 100

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
  YAML.load_file(petstore_schema_path)
end

def petstore_schema_path
  './spec/data/petstore-expanded.yaml'
end

def petstore_with_discriminator_schema
  YAML.load_file('./spec/data/petstore-with-discriminator.yaml')
end

def json_petstore_schema_path
  './spec/data/petstore.json'
end

def json_with_unsupported_extension_petstore_schema_path
  './spec/data/petstore.json.unsupported_extension'
end

def yaml_with_unsupported_extension_petstore_schema_path
  './spec/data/petstore.yaml.unsupported_extension'
end

def build_validate_test_schema(new_properties)
  b = YAML.load_file('./spec/data/validate_test.yaml')
  obj = b['paths']['/validate_test']['post']['requestBody']['content']['application/json']['schema']['properties']
  obj.merge!(change_string_key(new_properties))
  b
end

def change_string_key(hash)
  new_data = hash.map do |k, v|
    if v.kind_of?(Hash)
      [k.to_s, change_string_key(v)]
    elsif v.kind_of?(Array)
      [k.to_s, v.map { |child| change_string_key(child) }]
    else
      [k.to_s, v]
    end
  end

  new_data.to_h
end
