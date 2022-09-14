# frozen_string_literal: true

require "test_helper"

describe Committee::Middleware::RequestValidation do
  include Rack::Test::Methods

  def app
    @app
  end

  ARRAY_PROPERTY = [
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

  it "passes through a valid request" do
    @app = new_rack_app(schema: hyper_schema)
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "doesn't call error_handler (has a arg) when request is valid" do
    called_error = false
    pr = ->(_e) { called_error = true }
    @app = new_rack_app(schema: hyper_schema, error_handler: pr)
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert !called_error
  end

  it "doesn't call error_handler (has 2 args) when request is valid" do
    called_error = false
    pr = ->(_e, _env) { called_error = true }
    @app = new_rack_app(schema: hyper_schema, error_handler: pr)
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert !called_error
  end

  it "passes given a datetime and with coerce_date_times enabled on GET endpoint" do
    key_name = "update_time"
    params = {
        key_name => "2016-04-01T16:00:00.000+09:00",
        "query" => "cloudnasium"
    }

    check_parameter = lambda { |env|
      assert_equal DateTime, env['rack.request.query_hash'][key_name].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, coerce_date_times: true, schema: hyper_schema)

    get "/search/apps", params
    assert_equal 200, last_response.status
  end

  it "passes a nested object with recursive option" do
    key_name = "update_time"
    params = {
        key_name => "2016-04-01T16:00:00.000+09:00",
        "query" => "cloudnasium",
        "array_property" => ARRAY_PROPERTY
    }

    check_parameter = lambda { |env|
      hash = env['rack.request.query_hash']
      assert_equal DateTime, hash['array_property'].first['update_time'].class
      assert_equal 1, hash['array_property'].first['per_page']
      assert_equal DateTime, hash['array_property'].first['nested_coercer_object']['update_time'].class
      assert_equal 1, hash['array_property'].first['nested_no_coercer_object']['per_page']
      assert_equal 2, hash['array_property'].first['integer_array'][1]
      assert_equal DateTime, hash['array_property'].first['datetime_array'][0].class
      assert_equal DateTime, hash[key_name].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter,
                                    coerce_query_params: true,
                                    coerce_recursive: true,
                                    coerce_date_times: true,
                                    schema: hyper_schema)

    get "/search/apps", params
    assert_equal 200, last_response.status
  end

  it "passes a nested object with coerce_recursive false" do
    key_name = "update_time"
    params = {
        key_name => "2016-04-01T16:00:00.000+09:00",
        "query" => "cloudnasium",
        "array_property" => ARRAY_PROPERTY
    }

    @app = new_rack_app(coerce_query_params: true, coerce_date_times: true, coerce_recursive: false, schema: hyper_schema)

    get "/search/apps", params
    assert_equal 400, last_response.status # schema expect integer but we don't convert string to integer, so 400
  end

  it "passes a nested object with coerce_recursive default(true)" do
    key_name = "update_time"
    params = {
        key_name => "2016-04-01T16:00:00.000+09:00",
        "query" => "cloudnasium",
        "array_property" => ARRAY_PROPERTY
    }

    @app = new_rack_app(coerce_query_params: true, coerce_date_times: true, schema: hyper_schema)

    get "/search/apps", params
    assert_equal 200, last_response.status # schema expect integer but we don't convert string to integer, so 400
  end

  it "passes given a nested datetime and with coerce_recursive=true and coerce_date_times=true on POST endpoint" do
    key_name = "update_time"
    params = {
        key_name => "2016-04-01T16:00:00.000+09:00",
        "array_property" => ARRAY_PROPERTY
    }

    check_parameter = lambda { |env|
      hash = env['committee.params']
      assert_equal DateTime, hash['array_property'].first['update_time'].class
      assert_equal 1, hash['array_property'].first['per_page']
      assert_equal DateTime, hash['array_property'].first['nested_coercer_object']['update_time'].class
      assert_equal 1, hash['array_property'].first['nested_no_coercer_object']['per_page']
      assert_equal 2, hash['array_property'].first['integer_array'][1]
      assert_equal DateTime, hash['array_property'].first['datetime_array'][0].class
      assert_equal DateTime, env['committee.params'][key_name].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, coerce_date_times: true, coerce_recursive: true, schema: hyper_schema)

    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "passes given a nested datetime and with coerce_recursive=true and coerce_date_times=true on POST endpoint" do
    key_name = "update_time"
    params = {
        key_name => "2016-04-01T16:00:00.000+09:00",
        "array_property" => ARRAY_PROPERTY
    }

    check_parameter = lambda { |env|
      hash = env['committee.params']
      assert_equal String, hash['array_property'].first['update_time'].class
      assert_equal 1, hash['array_property'].first['per_page']
      assert_equal String, hash['array_property'].first['nested_coercer_object']['update_time'].class
      assert_equal 1, hash['array_property'].first['nested_no_coercer_object']['per_page']
      assert_equal 2, hash['array_property'].first['integer_array'][1]
      assert_equal String, hash['array_property'].first['datetime_array'][0].class
      assert_equal String, env['committee.params'][key_name].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, schema: hyper_schema)

    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "passes given a nested datetime and with coerce_recursive=false and coerce_date_times=true on POST endpoint" do
    key_name = "update_time"
    params = {
        key_name => "2016-04-01T16:00:00.000+09:00",
        "array_property" => ARRAY_PROPERTY
    }

    check_parameter = lambda { |env|
      hash = env['committee.params']
      assert_equal String, hash['array_property'].first['update_time'].class
      assert_equal 1, hash['array_property'].first['per_page']
      assert_equal String, hash['array_property'].first['nested_coercer_object']['update_time'].class
      assert_equal 1, hash['array_property'].first['nested_no_coercer_object']['per_page']
      assert_equal 2, hash['array_property'].first['integer_array'][1]
      assert_equal String, hash['array_property'].first['datetime_array'][0].class
      assert_equal DateTime, env['committee.params'][key_name].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, coerce_date_times: true, coerce_recursive: false, schema: hyper_schema)

    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "passes given a nested datetime and with coerce_recursive=false and coerce_date_times=false on POST endpoint" do
    key_name = "update_time"
    params = {
        key_name => "2016-04-01T16:00:00.000+09:00",
        "array_property" => ARRAY_PROPERTY
    }

    check_parameter = lambda { |env|
      hash = env['committee.params']
      assert_equal String, hash['array_property'].first['update_time'].class
      assert_equal 1, hash['array_property'].first['per_page']
      assert_equal String, hash['array_property'].first['nested_coercer_object']['update_time'].class
      assert_equal 1, hash['array_property'].first['nested_no_coercer_object']['per_page']
      assert_equal 2, hash['array_property'].first['integer_array'][1]
      assert_equal String, hash['array_property'].first['datetime_array'][0].class
      assert_equal String, env['committee.params'][key_name].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, schema: hyper_schema)

    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "passes given an invalid datetime string with coerce_date_times enabled" do
    @app = new_rack_app(coerce_date_times: true, schema: hyper_schema)
    params = {
        "update_time" => "invalid_datetime_format"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 400, last_response.status
    assert_match(/invalid request/i, last_response.body)
  end

  it "passes with coerce_date_times enabled and without a schema for a link" do
    @app = new_rack_app(coerce_date_times: true, schema: hyper_schema)
    header "Content-Type", "application/json"
    get "/apps", JSON.generate({})
    assert_equal 200, last_response.status
  end

  it "detects an invalid request" do
    @app = new_rack_app(schema: hyper_schema)
    header "Content-Type", "application/json"
    params = {
      "name" => 1
    }
    post "/apps", JSON.generate(params)
    assert_equal 400, last_response.status
    assert_match(/invalid request/i, last_response.body)
  end

  it "ignores errors when ignore_error: true" do
    @app = new_rack_app(schema: hyper_schema, ignore_error: true)
    header "Content-Type", "application/json"
    params = {
      "name" => 1
    }
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "calls error_handler (has a arg) when request is invalid" do
    called_err = nil
    pr = ->(e) { called_err = e }
    @app = new_rack_app(schema: hyper_schema, error_handler: pr)
    header "Content-Type", "application/json"
    params = {
      "name" => 1
    }
    _, err = capture_io do
      post "/apps", JSON.generate(params)
    end
    assert_kind_of Committee::InvalidRequest, called_err
    assert_match(/\[DEPRECATION\]/i, err)
  end

  it "calls error_handler (has two args) when request is invalid" do
    called_err = nil
    pr = ->(e, _env) { called_err = e }
    @app = new_rack_app(schema: hyper_schema, error_handler: pr)
    header "Content-Type", "application/json"
    params = {
      "name" => 1
    }
    post "/apps", JSON.generate(params)
    assert_kind_of Committee::InvalidRequest, called_err
  end

  it "rescues JSON errors" do
    @app = new_rack_app(schema: hyper_schema)
    header "Content-Type", "application/json"
    post "/apps", "{x:y}"
    assert_equal 400, last_response.status
    assert_match(/valid json/i, last_response.body)
  end

  it "calls error_handler (has a arg) when it rescues JSON errors" do
    called_err = nil
    pr = ->(e) { called_err = e }
    @app = new_rack_app(schema: hyper_schema, error_handler: pr)
    header "Content-Type", "application/json"
    _, err = capture_io do
      post "/apps", "{x:y}"
    end
    assert_kind_of JSON::ParserError, called_err
    assert_match(/\[DEPRECATION\]/i, err)
  end

  it "calls error_handler (has two args) when it rescues JSON errors" do
    called_err = nil
    pr = ->(e, _env) { called_err = e }
    @app = new_rack_app(schema: hyper_schema, error_handler: pr)
    header "Content-Type", "application/json"
    post "/apps", "{x:y}"
    assert_kind_of JSON::ParserError, called_err
  end

  it "takes a prefix" do
    @app = new_rack_app(prefix: "/v1", schema: hyper_schema)
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/v1/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "ignores paths outside the prefix" do
    @app = new_rack_app(prefix: "/v1", schema: hyper_schema)
    header "Content-Type", "text/html"
    get "/hello"
    assert_equal 200, last_response.status
  end

  it "routes to paths not in schema" do
    @app = new_rack_app(schema: hyper_schema)
    get "/not-a-resource"
    assert_equal 200, last_response.status
  end

  it "doesn't route to paths not in schema when in strict mode" do
    @app = new_rack_app(schema: hyper_schema, strict: true)
    get "/not-a-resource"
    assert_equal 404, last_response.status
  end

  it "optionally raises an error" do
    @app = new_rack_app(raise: true, schema: hyper_schema)
    header "Content-Type", "application/json"
    assert_raises(Committee::InvalidRequest) do
      post "/apps", "{x:y}"
    end
  end

  it "optionally skip content_type check" do
    @app = new_rack_app(check_content_type: false, schema: hyper_schema)
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "text/html"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "optionally coerces query params" do
    @app = new_rack_app(coerce_query_params: true, schema: hyper_schema)
    header "Content-Type", "application/json"
    get "/search/apps", {"per_page" => "10", "query" => "cloudnasium"}
    assert_equal 200, last_response.status
  end

  it "still raises an error if query param coercion is not possible" do
    @app = new_rack_app(coerce_query_params: true, schema: hyper_schema)
    header "Content-Type", "application/json"
    get "/search/apps", {"per_page" => "foo", "query" => "cloudnasium"}
    assert_equal 400, last_response.status
    assert_match(/invalid request/i, last_response.body)
  end

  it "passes through a valid request for OpenAPI" do
    check_parameter = lambda { |env|
      assert_equal 3, env['rack.request.query_hash']['limit']
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, schema: open_api_2_schema)
    get "/api/pets?limit=3", nil, { "HTTP_AUTH_TOKEN" => "xxx" }
    assert_equal 200, last_response.status
  end

  it "coerce form params" do
    check_parameter = lambda { |env|
      assert_equal 3, env['committee.params']['age']
      assert_equal 3, env['committee.request_body_hash']['age']
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, schema: open_api_2_form_schema, raise: true, allow_form_params: true, coerce_form_params: true)
    header "Content-Type", "application/x-www-form-urlencoded"
    post "/api/pets", "age=3&name=ab"
    assert_equal 200, last_response.status
  end

  it "detects an invalid request for OpenAPI" do
    @app = new_rack_app(schema: open_api_2_schema)
    get "/api/pets?limit=foo", nil, { "HTTP_AUTH_TOKEN" => "xxx" }
    assert_equal 400, last_response.status
    assert_match(/invalid request/i, last_response.body)
  end

  it "passes through a valid request for OpenAPI including path parameters" do
    @app = new_rack_app(schema: open_api_2_schema)
    # not that ID is expect to be an integer
    get "/api/pets/123"
    assert_equal 200, last_response.status
  end

  it "detects an invalid request for OpenAPI including path parameters" do
    @app = new_rack_app(schema: open_api_2_schema)
    # not that ID is expect to be an integer
    get "/api/pets/not-integer"
    assert_equal 400, last_response.status
    assert_match(/invalid request/i, last_response.body)
  end

  it "OpenAPI3 pass through a valid request" do
    @app = new_rack_app(schema: open_api_3_schema)
    get "/characters"
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

  it "not exist path and options" do
    options = {
        coerce_form_params: true,
        coerce_date_times: true,
        coerce_query_params: true,
        coerce_path_params: true,
        coerce_recursive: true
    }

    @app = new_rack_app({schema: hyper_schema}.merge(options))
    header "Content-Type", "application/x-www-form-urlencoded"
    post "/unknown"
    assert_equal 200, last_response.status
  end

  describe ':accept_request_filter' do
    [
      { description: 'when not specified, includes everything', accept_request_filter: nil, expected: { status: 400 } },
      { description: 'when predicate matches, performs validation', accept_request_filter: -> (request) { request.path.start_with?('/v1/a') }, expected: { status: 400 } },
      { description: 'when predicate does not match, skips validation', accept_request_filter: -> (request) { request.path.start_with?('/v1/x') }, expected: { status: 200 } },
    ].each do |h|
      description = h[:description]
      accept_request_filter = h[:accept_request_filter]
      expected = h[:expected]
      it description do
        @app = new_rack_app(prefix: '/v1', schema: hyper_schema, accept_request_filter: accept_request_filter)

        post '/v1/apps', '{x:y}'

        assert_equal expected[:status], last_response.status
      end
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
