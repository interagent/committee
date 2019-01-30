require_relative "../test_helper"

describe Committee::Middleware::ResponseValidation do
  include Rack::Test::Methods

  CHARACTERS_RESPONSE = {"Otonokizaka" => ["Honoka.Kousaka"]}

  def app
    @app
  end

  it "passes through a valid response" do
    @app = new_response_rack(JSON.generate(CHARACTERS_RESPONSE), {}, schema: open_api_3_schema)
    get "/characters"
    assert_equal 200, last_response.status
  end

  it "passes through a invalid json" do
    @app = new_response_rack("not_json", {}, schema: open_api_3_schema)

    get "/characters"

    assert_equal 500, last_response.status
    assert_equal "{\"id\":\"invalid_response\",\"message\":\"Response wasn't valid JSON.\"}", last_response.body
  end

  it "passes through not definition" do
    @app = new_response_rack(JSON.generate(CHARACTERS_RESPONSE), {}, schema: open_api_3_schema)
    get "/no_data"
    assert_equal 200, last_response.status
  end

  it "detects a response invalid due to schema" do
    @app = new_response_rack("[]", {}, schema: open_api_3_schema, raise: true)

    e = assert_raises(Committee::InvalidResponse) {
      get "/characters"
    }

    assert_match(/class is Array but it's not valid object/i, e.message)
  end

  it "passes through a 204 (no content) response" do
    @app = new_response_rack("", {}, {schema: open_api_3_schema}, {status: 204})
    post "/validate"
    assert_equal 204, last_response.status
  end

  it "passes through a valid response with prefix" do
    @app = new_response_rack(JSON.generate(CHARACTERS_RESPONSE), {}, schema: open_api_3_schema, prefix: "/v1")
    get "/v1/characters"
    assert_equal 200, last_response.status
  end

  it "passes through a invalid json with prefix" do
    @app = new_response_rack("not_json", {}, schema: open_api_3_schema, prefix: "/v1")

    get "/v1/characters"

    assert_equal 500, last_response.status
    assert_equal "{\"id\":\"invalid_response\",\"message\":\"Response wasn't valid JSON.\"}", last_response.body
  end

  it "rescues JSON errors" do
    @app = new_response_rack("_42", {}, schema: open_api_3_schema, raise: true)
    assert_raises(Committee::InvalidResponse) do
      get "/characters"
    end
  end

  it "not parameter requset" do
    @app = new_response_rack({integer: '1'}.to_json, {}, schema: open_api_3_schema, raise: true)

    assert_raises(Committee::InvalidResponse) do
      patch "/validate_no_parameter", {no_schema: 'no'}
    end
  end

  it "optionally validates non-2xx blank responses" do
    @app = new_response_rack("", {}, schema: open_api_3_schema, validate_success_only: false)
    get "/characters"
    assert_equal 200, last_response.status
  end

  it "optionally validates non-2xx invalid responses with invalid json" do
    @app = new_response_rack("{_}", {}, schema: open_api_3_schema, validate_success_only: false)
    get "/characters"
    assert_equal 500, last_response.status
    assert_match(/valid JSON/i, last_response.body)
  end

  describe 'check header' do
    it 'valid type header' do
      @app = new_response_rack({}.to_json, {'x-limit' => 1}, schema: open_api_3_schema, raise: true)

      get "/header"

      assert_equal 200, last_response.status
    end

    it 'invalid type header' do
      @app = new_response_rack({}.to_json, {'x-limit' => '1'}, schema: open_api_3_schema, raise: true)

      assert_raises(Committee::InvalidResponse) do
        get "/header"
      end
    end

    it 'invalid type but not check' do
      @app = new_response_rack({}.to_json, {'x-limit' => '1'}, schema: open_api_3_schema, raise: true, check_header: false)

      get "/header"

      assert_equal 200, last_response.status
    end
  end

  describe 'validate error option' do
    it "detects an invalid response status code" do
      @app = new_response_rack({ integer: '1' }.to_json,
                               {},
                               app_status: 400,
                               schema: open_api_3_schema,
                               raise: true,
                               validate_success_only: false)


      e = assert_raises(Committee::InvalidResponse) do
        get "/characters"
      end
      assert_match(/1 class is String/i, e.message)
    end

    it "detects an invalid response status code with validate_success_only=true" do
      @app = new_response_rack({ string_1: :honoka }.to_json,
                               {},
                               app_status: 400,
                               schema: open_api_3_schema,
                               raise: true,
                               validate_success_only: true)


      get "/characters"

      assert_equal 400, last_response.status
    end
  end

  private

  def new_response_rack(response, headers = {}, options = {}, rack_options = {})
    status = rack_options[:status] || 200
    headers = {
      "Content-Type" => "application/json"
    }.merge(headers)
    Rack::Builder.new {
      use Committee::Middleware::ResponseValidation, options
      run lambda { |_|
        [options.fetch(:app_status, status), headers, [response]]
      }
    }
  end
end
