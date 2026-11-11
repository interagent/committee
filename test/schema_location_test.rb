# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

describe 'YAML response error locations' do
  def response_error(schema, path, data, status: 200, method: 'GET', content_type: 'application/json', **options)
    app = ->(_env) { [status, { 'Content-Type' => content_type }, [JSON.generate(data)]] }
    middleware = Committee::Middleware::ResponseValidation.new(app, { schema: schema, raise: true, strict: true }.merge(options))
    assert_raises(Committee::InvalidResponse) { Rack::MockRequest.new(middleware).request(method, path) }
  end

  it 'includes the line of an inline OpenAPI 3 response property' do
    error = response_error(open_api_3_schema, '/validate', { 'string' => 1 }, method: 'POST')
    assert_includes error.message, 'normal.yaml:392'
    assert_kind_of OpenAPIParser::ValidateError, error.original_error
  end

  it 'includes the line in an external OpenAPI 3 reference' do
    error = response_error(open_api_3_schema, '/ref-sample', { 'sample' => 1 })
    assert_includes error.message, 'referee.yaml:15'
    assert_match(/expected string/, error.message)
  end

  it 'includes the original line of an inline OpenAPI 2 response schema' do
    schema = Committee::Drivers.load_from_file('test/data/openapi2/response_location.yml')
    error = response_error(schema, '/api/widgets', { 'count' => 'wrong' })
    assert_includes error.message, 'response_location.yml:18'
    assert_match(/failed schema/, error.message)
  end

  it 'includes the definition line for an OpenAPI 2 reference' do
    schema = Committee::Drivers.load_from_file('test/data/openapi2/response_location.yml')
    error = response_error(schema, '/api/widgets', { 'message' => 1 }, status: 400, validate_success_only: false)
    assert_includes error.message, 'response_location.yml:28'
  end

  it 'includes the response map line for an undefined OpenAPI 2 status' do
    schema = Committee::Drivers.load_from_file('test/data/openapi2/response_location.yml')
    error = response_error(schema, '/api/widgets', {}, status: 201)
    assert_includes error.message, 'response_location.yml:12'
  end

  it 'includes the produces line for an OpenAPI 2 Content-Type error' do
    schema = Committee::Drivers.load_from_file('test/data/openapi2/response_location.yml')
    error = response_error(schema, '/api/widgets', {}, content_type: 'text/plain')
    assert_includes error.message, 'response_location.yml:7'
  end

  it 'includes the response map line for an undefined OpenAPI 3 status' do
    error = response_error(open_api_3_schema, '/validate', {}, method: 'POST', status: 201)
    assert_includes error.message, 'normal.yaml:384'
  end

  it 'includes the response definition line for a strict OpenAPI 3 Content-Type error' do
    error = response_error(open_api_3_schema, '/validate', {}, method: 'POST', content_type: 'text/plain', strict_response_content_type: true)
    assert_includes error.message, 'normal.yaml:385'
  end

  it 'preserves the original message when loading from a Hash' do
    schema = Committee::Drivers.load_from_data(open_api_3_data, open_api_3_schema_path, parser_options: { strict_reference_validation: true })
    error = response_error(schema, '/validate', { 'string' => 1 }, method: 'POST')
    assert_equal error.original_error.message, error.message
  end

  it 'keeps locations after the main YAML file has been removed' do
    Dir.mktmpdir('committee-schema-locations') do |dir|
      path = File.join(dir, 'schema.yml')
      File.write(path, File.read('test/data/openapi2/response_location.yml'))
      schema = Committee::Drivers.load_from_file(path)
      File.unlink(path)
      error = response_error(schema, '/api/widgets', { 'count' => 'wrong' })
      assert_includes error.message, "#{path}:18"
    end
  end

  it 'locates properties inherited through a YAML merge' do
    Dir.mktmpdir('committee-merged-schema') do |dir|
      path = File.join(dir, 'merged.yml')
      yaml = File.read('test/data/openapi2/response_location.yml')
      yaml = yaml.sub("            type: object\n            properties:\n              count:\n                type: integer", "            <<: &response\n              type: object\n              properties:\n                count:\n                  type: integer")
      yaml = yaml.sub("            $ref: '#/definitions/Error'", '            <<: *response')
      File.write(path, yaml)
      schema = Committee::Drivers.load_from_file(path)

      [200, 400].each do |status|
        error = response_error(schema, '/api/widgets', { 'count' => 'wrong' }, status: status, validate_success_only: false)
        assert_includes error.message, "#{path}:19"
      end
    end
  end

  it 'locates an OpenAPI 3.1 property inside a referenced schema' do
    error = response_error(open_api_3_1_schema, '/items/1', ValidItem.merge('rating' => 6))
    assert_includes error.message, '3_1.yaml:127'
  end

  it 'preserves the validation error when a referenced YAML file is unavailable' do
    Dir.mktmpdir('committee-remote-schema') do |dir|
      path = File.join(dir, 'schema.yml')
      reference_path = File.join(dir, 'referee.yaml')
      File.write(path, File.read(open_api_3_schema_path))
      File.write(reference_path, File.read('test/data/openapi3/referee.yaml'))
      schema = Committee::Drivers.load_from_file(path, parser_options: { strict_reference_validation: true })
      File.unlink(reference_path)

      error = response_error(schema, '/ref-sample', { 'sample' => 1 })
      assert_equal error.original_error.message, error.message
    end
  end
end
