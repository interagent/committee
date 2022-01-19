# frozen_string_literal: true

require "test_helper"

describe Committee::Middleware::RequestValidation do
  include Rack::Test::Methods

  def app
    @app
  end

  it "OpenAPI3 pass through a valid request" do
    @app = new_rack_app(schema: open_api_3_schema)
    params = {
        "string_post_1" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/characters", JSON.generate(params)

    assert_equal 200, last_response.status
  end

  it "not parameter request" do
    check_parameter_string = lambda { |_|
      [200, {integer: 1}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter_string, schema: open_api_3_schema)

    put "/validate_no_parameter", {no_schema: 'no'}
  end

  it "passes given a datetime and with coerce_date_times enabled on GET endpoint" do
    params = { "datetime_string" => "2016-04-01T16:00:00.000+09:00" }

    check_parameter = lambda { |env|
      assert_equal DateTime, env['committee.query_hash']["datetime_string"].class
      assert_equal String, env['rack.request.query_hash']["datetime_string"].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, schema: open_api_3_schema, coerce_date_times: true, query_hash_key: "committee.query_hash")

    get "/string_params_coercer", params
    assert_equal 200, last_response.status
  end

  it "passes given a datetime and with coerce_date_times enabled on GET endpoint overwrite query_hash" do
    params = { "datetime_string" => "2016-04-01T16:00:00.000+09:00" }

    check_parameter = lambda { |env|
      assert_nil env['committee.query_hash']
      assert_equal DateTime, env['rack.request.query_hash']["datetime_string"].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, schema: open_api_3_schema, coerce_date_times: true, query_hash_key: "rack.request.query_hash")

    get "/string_params_coercer", params
    assert_equal 200, last_response.status
  end

  it "passes given a valid parameter on GET endpoint with request body and allow_get_body=true" do
    params = { "data" => "abc" }

    @app = new_rack_app(schema: open_api_3_schema, allow_get_body: true)

    get "/get_endpoint_with_required_parameter", { no_problem: true }, { input: params.to_json }
    assert_equal 200, last_response.status
  end

  it "errors given valid parameter on GET endpoint with request body and allow_get_body=false" do
    params = { "data" => "abc" }

    @app = new_rack_app(schema: open_api_3_schema, allow_get_body: false)

    get "/get_endpoint_with_required_parameter", { no_problem: true }, { input: params.to_json }
    assert_equal 400, last_response.status
  end

  it "passes given a datetime and with coerce_date_times enabled on GET endpoint with request body" do
    params = { "datetime_string" => "2016-04-01T16:00:00.000+09:00" }

    check_parameter = lambda { |env|
      assert_equal DateTime, env['committee.params']["datetime_string"].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter,
                                    schema: open_api_3_schema,
                                    coerce_date_times: true,
                                    allow_get_body: true)

    get "/string_params_coercer", { no_problem: true }, { input: params.to_json }
    assert_equal 200, last_response.status
  end

  it "passes given a datetime and with coerce_date_times enabled on POST endpoint" do
    params = {
        "nested_array" => [
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
                "nested_coercer_object" => {
                    "update_time" => "2016-04-01T16:00:00.000+09:00",
                },
                "nested_no_coercer_object" => {
                    "update_time" => "2016-04-01T16:00:00.000+09:00",
                },
                "nested_coercer_array" => [
                    {
                        "update_time" => "2016-04-01T16:00:00.000+09:00",
                    }
                ],
                "nested_no_coercer_array" => [
                    {
                        "update_time" => "2016-04-01T16:00:00.000+09:00",
                    }
                ]
            },
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
            }
        ]
    }

    check_parameter = lambda { |env|
      nested_array = env['committee.params']["nested_array"]
      first_data = nested_array[0]
      assert_kind_of DateTime, first_data["update_time"]

      second_data = nested_array[1]
      assert_kind_of DateTime, second_data["update_time"]

      assert_kind_of DateTime, first_data["nested_coercer_object"]["update_time"]

      assert_kind_of String, first_data["nested_no_coercer_object"]["update_time"]

      assert_kind_of DateTime, first_data["nested_coercer_array"].first["update_time"]
      assert_kind_of String, first_data["nested_no_coercer_array"].first["update_time"]
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, schema: open_api_3_schema, coerce_date_times: true, coerce_recursive: true)

    header "Content-Type", "application/json"
    post "/string_params_coercer", JSON.generate(params)

    assert_equal 200, last_response.status
  end

  it "passes given an invalid datetime string with coerce_date_times enabled" do
    @app = new_rack_app(schema: open_api_3_schema, coerce_date_times: true)
    params = {
        "datetime_string" => "invalid_datetime_format"
    }
    get "/string_params_coercer", params

    assert_equal 400, last_response.status
    assert_match(/invalid_datetime/i, last_response.body)
  end

  it "passes a nested object with recursive option" do
    params = {
        "nested_array" => [
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
                "per_page" => "1",
            }
        ],
    }

    check_parameter = lambda { |env|
      # hash = env["committee.query_hash"] # 5.0.x-
      hash = env["rack.request.query_hash"]
      assert_equal DateTime, hash['nested_array'].first['update_time'].class
      assert_equal 1, hash['nested_array'].first['per_page']

      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter,
                                    coerce_query_params: true,
                                    coerce_recursive: true,
                                    coerce_date_times: true,
                                    schema: open_api_3_schema)

    get "/string_params_coercer", params

    assert_equal 200, last_response.status
  end

  it "passes given a nested datetime and with coerce_recursive=true and coerce_date_times=true on POST endpoint" do
    params = {
        "nested_array" => [
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
                "per_page" => 1,
                "nested_coercer_object" => {
                    "update_time" => "2016-04-01T16:00:00.000+09:00",
                    "threshold" => 1.5
                },
                "nested_no_coercer_object" => {
                    "per_page" => 1,
                    "threshold" => 1.5
                },
                "nested_coercer_array" => [
                    {
                        "update_time" => "2016-04-01T16:00:00.000+09:00",
                        "threshold" => 1.5
                    }
                ],
                "nested_no_coercer_array" => [
                    {
                        "per_page" => 1,
                        "threshold" => 1.5
                    }
                ],
                "integer_array" => [
                    1, 2, 3
                ],
                "datetime_array" => [
                    "2016-04-01T16:00:00.000+09:00",
                    "2016-04-01T17:00:00.000+09:00",
                    "2016-04-01T18:00:00.000+09:00"
                ]
            },
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
                "per_page" => 1,
                "threshold" => 1.5
            },
            {
                "threshold" => 1.5,
                "per_page" => 1
            }
        ]
    }

    check_parameter = lambda { |env|
      hash = env['committee.params']
      array = hash['nested_array']

      assert_equal DateTime, array.first['update_time'].class
      assert_equal 1, array.first['per_page']
      assert_equal DateTime, array.first['nested_coercer_object']['update_time'].class
      assert_equal 1, array.first['nested_no_coercer_object']['per_page']
      assert_equal 2, array.first['integer_array'][1]
      assert_equal DateTime, array.first['datetime_array'][0].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter,
                                    coerce_date_times: true,
                                    schema: open_api_3_schema)

    header "Content-Type", "application/json"
    post "/string_params_coercer", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "OpenAPI3 detects an invalid request" do
    @app = new_rack_app(schema: open_api_3_schema, strict: true)
    header "Content-Type", "application/json"
    params = {
        "string_post_1" => 1
    }
    post "/characters", JSON.generate(params)
    assert_equal 400, last_response.status
    assert_match(/expected string, but received Integer:/i, last_response.body)
  end

  it "rescues JSON errors" do
    @app = new_rack_app(schema: open_api_3_schema)
    header "Content-Type", "application/json"
    post "/characters", "{x:y}"
    assert_equal 400, last_response.status
    assert_match(/valid json/i, last_response.body)
  end

  it "take a prefix" do
    @app = new_rack_app(prefix: "/v1", schema: open_api_3_schema)
    params = {
        "string_post_1" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/v1/characters", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "take a prefix with invalid data" do
    @app = new_rack_app(prefix: "/v1", schema: open_api_3_schema)
    params = {
        "string_post_1" => 1
    }
    header "Content-Type", "application/json"
    post "/v1/characters", JSON.generate(params)
    assert_equal 400, last_response.status
    assert_match(/expected string, but received Integer: /i, last_response.body)
  end

  it "ignores paths outside the prefix" do
    @app = new_rack_app(prefix: "/v1", schema: open_api_3_schema)
    params = {
        "string_post_1" => 1
    }
    header "Content-Type", "application/json"
    post "/characters", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "don't check prefix with no option" do
    @app = new_rack_app(schema: open_api_3_schema)
    params = {
        "string_post_1" => 1
    }
    header "Content-Type", "application/json"
    post "/v1/characters", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "OpenAPI3 pass not exist href" do
    @app = new_rack_app(schema: open_api_3_schema)
    get "/unknown"
    assert_equal 200, last_response.status
  end

  it "OpenAPI3 pass not exist href in strict mode" do
    @app = new_rack_app(schema: open_api_3_schema, strict: true)
    get "/unknown"
    assert_equal 404, last_response.status
  end

  it "OpenAPI3 parser not exist required key" do
    @app = new_rack_app(raise: true, schema: open_api_3_schema)

    e = assert_raises(Committee::InvalidRequest) do
      get "/validate", nil
    end

    assert_match(/missing required parameters: query_string/i, e.message)
  end

  it "raises error when required path parameter is invalid" do
    @app = new_rack_app(raise: true, schema: open_api_3_schema)

    e = assert_raises(Committee::InvalidRequest) do
      not_an_integer = 'abc'
      get "/coerce_path_params/#{not_an_integer}", nil
    end

    assert_match(/expected integer, but received String: \"abc\"/i, e.message)
  end

  it "optionally raises an error" do
    @app = new_rack_app(raise: true, schema: open_api_3_schema)
    header "Content-Type", "application/json"
    assert_raises(Committee::InvalidRequest) do
      post "/characters", "{x:y}"
    end
  end

  it "optionally coerces query params" do
    @app = new_rack_app(coerce_query_params: true, schema: open_api_3_schema)
    header "Content-Type", "application/json"
    get "/string_params_coercer", {"integer_1" => "1"}
    assert_equal 200, last_response.status
  end

  it "still raises an error if query param coercion is not possible" do
    @app = new_rack_app(coerce_query_params: false, schema: open_api_3_schema)
    header "Content-Type", "application/json"
    get "/string_params_coercer", {"integer_1" => "1"}

    assert_equal 400, last_response.status
    assert_match(/expected integer, but received String:/i, last_response.body)
  end

  it "passes through a valid request for OpenAPI3" do
    check_parameter = lambda { |env|
      # assert_equal 3, env['committee.query_hash']['limit'] #5.0.x-
      assert_equal 3, env['rack.request.query_hash']['limit'] #5.0.x-
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, schema: open_api_3_schema)
    get "/characters?limit=3"
    assert_equal 200, last_response.status
  end

  it "detects an invalid request for OpenAPI" do
    @app = new_rack_app(schema: open_api_3_schema)
    get "/characters?limit=foo"

    assert_equal 400, last_response.status
    assert_match(/expected integer, but received String: \\"foo\\"/i, last_response.body)
  end

  it "ignores errors when ignore_error: true" do
    @app = new_rack_app(schema: open_api_3_schema, ignore_error: true)
    get "/characters?limit=foo"

    assert_equal 200, last_response.status
  end

  it "coerce string to integer" do
    check_parameter_string = lambda { |env|
      assert env['committee.params']['integer'].is_a?(Integer)
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter_string, schema: open_api_3_schema, coerce_path_params: true)
    get "/coerce_path_params/1"
  end

  it "coerce string and save path hash" do
    @app = new_rack_app_with_lambda(lambda do |env|
      assert_equal 21, env['committee.params']['integer']
      assert_equal 21, env['committee.params'][:integer]
      assert_equal 21, env['committee.path_hash']['integer']
      assert_equal 21, env['committee.path_hash'][:integer]
      [204, {}, []]
    end, schema: open_api_3_schema)

    header "Content-Type", "application/json"
    post '/parameter_option_test/21'
    assert_equal 204, last_response.status
  end

  it "coerce string and save request body hash" do
    @app = new_rack_app_with_lambda(lambda do |env|
      assert_equal 21, env['committee.params']['integer'] # path parameter has precedence
      assert_equal 21, env['committee.params'][:integer]
      assert_equal 42, env['committee.request_body_hash']['integer']
      assert_equal 42, env['committee.request_body_hash'][:integer]
      [204, {}, []]
    end, schema: open_api_3_schema)

    params = {integer: 42}

    header "Content-Type", "application/json"
    post '/parameter_option_test/21', JSON.generate(params)
    assert_equal 204, last_response.status
  end

  it "unpacker test" do
    @app = new_rack_app_with_lambda(lambda do |env|
      assert_equal '21', env['committee.params']['integer'] # query parameter has precedence
      assert_equal '21', env['committee.params'][:integer]
      assert_equal '21', env['rack.request.query_hash']['integer']
      assert_equal 42, env['committee.request_body_hash']['integer']
      [204, {}, []]
    end, schema: open_api_3_schema, raise: true)

    header "Content-Type", "application/x-www-form-urlencoded"
    post '/validate?integer=21', "integer=42"
    assert_equal 204, last_response.status
  end

  it "OpenAPI3 raise not support method" do
    @app = new_rack_app(schema: open_api_3_schema)

    e = assert_raises(RuntimeError) {
      custom_request('TRACE', "/characters")
    }

    assert_equal 'Committee OpenAPI3 not support trace method', e.message
  end  

  describe 'check header' do
    [
      { check_header: true, description: 'valid value', value: 1, expected: { status: 200 } },
      { check_header: true, description: 'missing value', value: nil, expected: { status: 400, error: 'missing required parameters: integer' } },
      { check_header: true, description: 'invalid value', value: 'x', expected: { status: 400, error: 'expected integer, but received String: \\"x\\"' } },

      { check_header: false, description: 'valid value', value: 1, expected: { status: 200 } },
      { check_header: false, description: 'missing value', value: nil, expected: { status: 200 } },
      { check_header: false, description: 'invalid value', value: 'x', expected: { status: 200 } },
    ].each do |h|
      check_header = h[:check_header]
      description = h[:description]
      value = h[:value]
      expected = h[:expected]
      describe "when #{check_header}" do
        %w(get post put patch delete options).each do |method|
          describe method do
            describe description do
              it (expected[:error].nil? ? 'should pass' : 'should fail') do
                @app = new_rack_app(schema: open_api_3_schema, check_header: check_header)

                header 'integer', value
                send(method, "/header")

                assert_equal expected[:status], last_response.status
                assert_match(expected[:error], last_response.body) if expected[:error]
              end
            end
          end
        end
      end
    end
  end

  describe ':accept_request_filter' do
    [
      { description: 'when not specified, includes everything', accept_request_filter: nil, expected: { status: 400 } },
      { description: 'when predicate matches, performs validation', accept_request_filter: -> (request) { request.path.start_with?('/v1/c') }, expected: { status: 400 } },
      { description: 'when predicate does not match, skips validation', accept_request_filter: -> (request) { request.path.start_with?('/v1/x') }, expected: { status: 200 } },
    ].each do |h|
      description = h[:description]
      accept_request_filter = h[:accept_request_filter]
      expected = h[:expected]
      it description do
        @app = new_rack_app(prefix: '/v1', schema: open_api_3_schema, accept_request_filter: accept_request_filter)

        post 'v1/characters', JSON.generate(string_post_1: 1)

        assert_equal expected[:status], last_response.status
      end
    end
  end

  it 'does not suppress application error' do
    @app = new_rack_app_with_lambda(lambda { |_|
      JSON.load('-') # invalid json
    }, schema: open_api_3_schema, raise: true)

    assert_raises(JSON::ParserError) do
      get "/error", nil
    end
  end

  private

  def new_rack_app(options = {})
    new_rack_app_with_lambda(lambda { |_|
      [200, {}, []]
    }, options)
  end

  def new_rack_app_with_lambda(check_lambda, options = {})
    # TODO: delete when 5.0.0 released because default value changed
    options[:parse_response_by_content_type] = true if options[:parse_response_by_content_type] == nil

    Rack::Builder.new {
      use Committee::Middleware::RequestValidation, options
      run check_lambda
    }
  end
end
