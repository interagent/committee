require_relative "../test_helper"

describe Committee::Middleware::RequestValidation do
  include Rack::Test::Methods

  def app
    @app
  end

  it "OpenAPI3 pass through a valid request" do
    @app = new_rack_app(open_api_3: open_api_3_schema)
    params = {
        "string_post_1" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/characters", JSON.generate(params)

    assert_equal 200, last_response.status
  end

  it "not parameter requset" do
    check_parameter_string = lambda { |_|
      [200, {integer: 1}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter_string, open_api_3: open_api_3_schema)

    put "/validate_no_parameter", {no_schema: 'no'}
  end

  it "passes given a datetime and with coerce_date_times enabled on GET endpoint" do
    params = { "datetime_string" => "2016-04-01T16:00:00.000+09:00" }

    check_parameter = lambda { |env|
      assert_equal DateTime, env['rack.request.query_hash']["datetime_string"].class
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, open_api_3: open_api_3_schema, coerce_date_times: true)

    get "/string_params_coercer", params
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

    @app = new_rack_app_with_lambda(check_parameter, open_api_3: open_api_3_schema, coerce_date_times: true, coerce_recursive: true)

    header "Content-Type", "application/json"
    post "/string_params_coercer", JSON.generate(params)

    assert_equal 200, last_response.status
  end

  it "passes given an invalid datetime string with coerce_date_times enabled" do
    @app = new_rack_app(open_api_3: open_api_3_schema, coerce_date_times: true)
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
      hash = env['rack.request.query_hash']
      assert_equal DateTime, hash['nested_array'].first['update_time'].class
      assert_equal 1, hash['nested_array'].first['per_page']

      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter,
                                    coerce_query_params: true,
                                    coerce_recursive: true,
                                    coerce_date_times: true,
                                    open_api_3: open_api_3_schema)

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
                                    open_api_3: open_api_3_schema)

    header "Content-Type", "application/json"
    post "/string_params_coercer", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "OpenAPI3 detects an invalid request" do
    @app = new_rack_app(open_api_3: open_api_3_schema, strict: true)
    header "Content-Type", "application/json"
    params = {
        "string_post_1" => 1
    }
    post "/characters", JSON.generate(params)
    assert_equal 400, last_response.status
    # FIXME: when ruby 2.3 dropped, fix because ruby 2.3 return Fixnum, ruby 2.4 or later return Integer
    assert_match(/1 class is #{1.class}/i, last_response.body)
  end

  it "rescues JSON errors" do
    @app = new_rack_app(open_api_3: open_api_3_schema)
    header "Content-Type", "application/json"
    post "/apps", "{x:y}"
    assert_equal 400, last_response.status
    assert_match(/valid json/i, last_response.body)
  end

  it "take a prefix" do
    @app = new_rack_app(prefix: "/v1", open_api_3: open_api_3_schema)
    params = {
        "string_post_1" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/v1/characters", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "take a prefix with invalid data" do
    @app = new_rack_app(prefix: "/v1", open_api_3: open_api_3_schema)
    params = {
        "string_post_1" => 1
    }
    header "Content-Type", "application/json"
    post "/v1/characters", JSON.generate(params)
    assert_equal 400, last_response.status
    assert_match(/1 class is/i, last_response.body)
  end

  it "ignores paths outside the prefix" do
    @app = new_rack_app(prefix: "/v1", open_api_3: open_api_3_schema)
    params = {
        "string_post_1" => 1
    }
    header "Content-Type", "application/json"
    post "/characters", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "don't check prefix with no option" do
    @app = new_rack_app(open_api_3: open_api_3_schema)
    params = {
        "string_post_1" => 1
    }
    header "Content-Type", "application/json"
    post "/v1/characters", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "OpenAPI3 pass not exist href" do
    @app = new_rack_app(open_api_3: open_api_3_schema)
    get "/unknown"
    assert_equal 200, last_response.status
  end

  it "OpenAPI3 pass not exist href in strict mode" do
    @app = new_rack_app(open_api_3: open_api_3_schema, strict: true)
    get "/unknown"
    assert_equal 404, last_response.status
  end

  it "optionally raises an error" do
    @app = new_rack_app(raise: true, open_api_3: open_api_3_schema)
    header "Content-Type", "application/json"
    assert_raises(Committee::InvalidRequest) do
      post "/characters", "{x:y}"
    end
  end

  it "optionally coerces query params" do
    @app = new_rack_app(coerce_query_params: true, open_api_3: open_api_3_schema)
    header "Content-Type", "application/json"
    get "/string_params_coercer", {"integer_1" => "1"}
    assert_equal 200, last_response.status
  end

  it "still raises an error if query param coercion is not possible" do
    @app = new_rack_app(coerce_query_params: false, open_api_3: open_api_3_schema)
    header "Content-Type", "application/json"
    get "/string_params_coercer", {"integer_1" => "1"}

    assert_equal 400, last_response.status
    assert_match(/1 class/i, last_response.body)
  end

  it "passes through a valid request for OpenAPI3" do
    check_parameter = lambda { |env|
      assert_equal 3, env['rack.request.query_hash']['limit']
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter, open_api_3: open_api_3_schema)
    get "/characters?limit=3"
    assert_equal 200, last_response.status
  end

  it "detects an invalid request for OpenAPI" do
    @app = new_rack_app(open_api_3: open_api_3_schema)
    get "/characters?limit=foo"

    assert_equal 400, last_response.status
    assert_match(/foo class/i, last_response.body)
  end

  it "coerce string to integer" do
    check_parameter_string = lambda { |env|
      assert env['committee.params']['integer'].is_a?(Integer)
      [200, {}, []]
    }

    @app = new_rack_app_with_lambda(check_parameter_string, open_api_3: open_api_3_schema, coerce_path_params: true)
    get "/coerce_path_params/1"
  end

  it "OpenAPI3 raise not support method" do
    @app = new_rack_app(open_api_3: open_api_3_schema)

    e = assert_raises(RuntimeError) {
      head "/characters", {}
    }

    assert_equal 'Committee OpenAPI3 not support head method', e.message
  end

  describe 'check header' do
    it 'no required header' do
      @app = new_rack_app(open_api_3: open_api_3_schema, check_header: true)

      get "/header"

      assert_equal 400, last_response.status
      assert_match(/required parameters integer not exist/i, last_response.body)
    end

    it 'no required header but not check' do
      @app = new_rack_app(open_api_3: open_api_3_schema, check_header: false)

      get "/header"

      assert_equal 200, last_response.status
    end
  end

  private

  def new_rack_app(options = {})
    new_rack_app_with_lambda(lambda { |_|
      [200, {}, []]
    }, options)
  end

  def new_rack_app_with_lambda(check_lambda, options = {})
    Rack::Builder.new {
      use Committee::Middleware::RequestValidation, options
      run check_lambda
    }
  end
end
