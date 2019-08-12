# frozen_string_literal: true

require "test_helper"

describe Committee::Drivers::OpenAPI2::Driver do
  before do
    @driver = Committee::Drivers::OpenAPI2::Driver.new
  end

  it "has a name" do
    assert_equal :open_api_2, @driver.name
  end

  it "has a schema class" do
    assert_equal Committee::Drivers::OpenAPI2::Schema, @driver.schema_class
  end

  it "parses an OpenAPI 2 spec" do
    schema = @driver.parse(open_api_2_data)
    assert_kind_of Committee::Drivers::OpenAPI2::Schema, schema
    assert_kind_of JsonSchema::Schema, schema.definitions
    assert_equal @driver, schema.driver

    assert_kind_of Hash, schema.routes
    refute schema.routes.empty?
    assert(schema.routes.keys.all? { |m|
      ["DELETE", "GET", "PATCH", "POST", "PUT"].include?(m)
    })

    schema.routes.each do |(_, method_routes)|
      method_routes.each do |regex, link|
        assert_kind_of Regexp, regex
        assert_kind_of Committee::Drivers::OpenAPI2::Link, link

        # verify that we've correct generated a parameters schema for each link
        if link.target_schema
          assert_kind_of JsonSchema::Schema, link.schema if link.schema
        end

        if link.target_schema
          assert_kind_of JsonSchema::Schema, link.target_schema
        end
      end
    end
  end

  it "names capture groups into href regexes" do
    schema = @driver.parse(open_api_2_data)
    assert_equal %r{^\/api\/pets\/(?<id>[^\/]+)$}.inspect,
      schema.routes["DELETE"][0][0].inspect
  end

  it "prefers a 200 response first" do
    schema_data = schema_data_with_responses({
      '201' => { 'schema' => { 'description' => '201 response' } },
      '200' => { 'schema' => { 'description' => '200 response' } },
    })

    schema = @driver.parse(schema_data)
    link = schema.routes['GET'][0][1]
    assert_equal 200, link.status_success
    assert_equal({ 'description' => '200 response' }, link.target_schema.data)
  end

  it "prefers a 201 response next" do
    schema_data = schema_data_with_responses({
      '302' => { 'schema' => { 'description' => '302 response' } },
      '201' => { 'schema' => { 'description' => '201 response' } },
    })

    schema = @driver.parse(schema_data)
    link = schema.routes['GET'][0][1]
    assert_equal 201, link.status_success
    assert_equal({ 'description' => '201 response' }, link.target_schema.data)
  end

  it "prefers any three-digit response next" do
    schema_data = schema_data_with_responses({
      'default' => { 'schema' => { 'description' => 'default response' } },
      '302' => { 'schema' => { 'description' => '302 response' } },
    })

    schema = @driver.parse(schema_data)
    link = schema.routes['GET'][0][1]
    assert_equal 302, link.status_success
    assert_equal({ 'description' => '302 response' }, link.target_schema.data)
  end

  it "prefers any numeric three-digit response next" do
    schema_data = schema_data_with_responses({
      'default' => { 'schema' => { 'description' => 'default response' } },
      302 => { 'schema' => { 'description' => '302 response' } },
    })

    schema = @driver.parse(schema_data)
    link = schema.routes['GET'][0][1]
    assert_equal 302, link.status_success
    assert_equal({ 'description' => '302 response' }, link.target_schema.data)
  end

  it "falls back to no response" do
    schema_data = schema_data_with_responses({})

    schema = @driver.parse(schema_data)
    link = schema.routes['GET'][0][1]
    assert_nil link.status_success
    assert_nil link.target_schema
  end

  it "refuses to parse other version of OpenAPI" do
    data = open_api_2_data
    data['swagger'] = '3.0'
    e = assert_raises(ArgumentError) do
      @driver.parse(data)
    end
    assert_equal "Committee: driver requires OpenAPI 2.0.", e.message
  end

  it "refuses to parse a spec without mandatory fields" do
    data = open_api_2_data
    data['definitions'] = nil
    e = assert_raises(ArgumentError) do
      @driver.parse(data)
    end
    assert_equal "Committee: no definitions section in spec data.", e.message
  end

  it "defaults to coercing form parameters" do
    assert_equal true, @driver.default_coerce_form_params
  end

  it "defaults to path parameters" do
    assert_equal true, @driver.default_path_params
  end

  it "defaults to query parameters" do
    assert_equal true, @driver.default_query_params
  end

  def schema_data_with_responses(response_data)
    {
      'swagger' => '2.0',
      'consumes' => ['application/json'],
      'produces' => ['application/json'],
      'paths' => {
        '/foos' => {
          'get' => {
            'responses' => response_data,
          },
        },
      },
      'definitions' => {},
    }
  end
end

