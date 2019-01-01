require_relative "../test_helper"

describe Committee::Middleware::ResponseValidation do
  include Rack::Test::Methods

  CHARACTERS_RESPONSE = {"Otonokizaka" => ["Honoka.Kousaka"]}

  def app
    @app
  end

  it "passes through a valid response" do
    @app = new_response_rack(JSON.generate(CHARACTERS_RESPONSE), {}, open_api_3: open_api_3_schema)
    get "/characters"
    assert_equal 200, last_response.status
  end

  it "passes through a invalid json" do
    @app = new_response_rack("not_json", {}, open_api_3: open_api_3_schema)

    get "/characters"

    assert_equal 500, last_response.status
    assert_equal "{\"id\":\"invalid_response\",\"message\":\"Response wasn't valid JSON.\"}", last_response.body
  end

  it "passes through not definition" do
    @app = new_response_rack(JSON.generate(CHARACTERS_RESPONSE), {}, open_api_3: open_api_3_schema)
    get "/no_data"
    assert_equal 200, last_response.status
  end

  it "detects a response invalid due to schema" do
    @app = new_response_rack("[]", {}, open_api_3: open_api_3_schema, raise: true)

    e = assert_raises(Committee::InvalidResponse) {
      get "/characters"
    }

    assert_match(/class is Array but it's not valid object/i, e.message)
  end

  it "passes through a 204 (no content) response" do
    @app = new_response_rack("", {}, {open_api_3: open_api_3_schema}, {status: 204})
    post "/validate"
    assert_equal 204, last_response.status
  end

  it "passes through a valid response with prefix" do
    @app = new_response_rack(JSON.generate(CHARACTERS_RESPONSE), {}, open_api_3: open_api_3_schema, prefix: "/v1")
    get "/v1/characters"
    assert_equal 200, last_response.status
  end

  it "passes through a invalid json with prefix" do
    @app = new_response_rack("not_json", {}, open_api_3: open_api_3_schema, prefix: "/v1")

    get "/v1/characters"

    # TODO: support prefix
    assert_equal 200, last_response.status
    # assert_equal 500, last_response.status
    # assert_equal "{\"id\":\"invalid_response\",\"message\":\"Response wasn't valid JSON.\"}", last_response.body
  end

  it "rescues JSON errors" do
    @app = new_response_rack("_42", {}, open_api_3: open_api_3_schema, raise: true)
    assert_raises(Committee::InvalidResponse) do
      get "/characters"
    end
  end

  it "not parameter requset" do
    @app = new_response_rack({integer: '1'}.to_json, {}, open_api_3: open_api_3_schema, raise: true)

    assert_raises(Committee::InvalidResponse) do
      patch "/validate_no_parameter", {no_schema: 'no'}
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
