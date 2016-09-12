require_relative "../test_helper"

describe Committee::Middleware::RequestValidation do
  include Rack::Test::Methods

  def app
    @app
  end

  it "passes through a valid request" do
    @app = new_rack_app
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "detects an invalid request" do
    @app = new_rack_app
    header "Content-Type", "application/json"
    params = {
      "name" => 1
    }
    post "/apps", JSON.generate(params)
    assert_equal 400, last_response.status
    assert_match /invalid request/i, last_response.body
  end

  it "rescues JSON errors" do
    @app = new_rack_app
    header "Content-Type", "application/json"
    post "/apps", "{x:y}"
    assert_equal 400, last_response.status
    assert_match /valid json/i, last_response.body
  end

  it "takes a prefix" do
    @app = new_rack_app(prefix: "/v1")
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/v1/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "ignores paths outside the prefix" do
    @app = new_rack_app(prefix: "/v1")
    header "Content-Type", "text/html"
    get "/hello"
    assert_equal 200, last_response.status
  end

  it "warns when sending a deprecated string" do
    mock(Committee).warn_deprecated.with_any_args
    @app = new_rack_app(schema: File.read("./test/data/schema.json"))
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "routes to paths not in schema" do
    @app = new_rack_app
    get "/not-a-resource"
    assert_equal 200, last_response.status
  end

  it "doesn't route to paths not in schema when in strict mode" do
    @app = new_rack_app(strict: true)
    get "/not-a-resource"
    assert_equal 404, last_response.status
  end

  it "optionally raises an error" do
    @app = new_rack_app(raise: true)
    header "Content-Type", "application/json"
    assert_raises(Committee::InvalidRequest) do
      post "/apps", "{x:y}"
    end
  end

  it "optionally skip content_type check" do
    @app = new_rack_app(check_content_type: false)
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "text/html"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "optionally coerces query params" do
    @app = new_rack_app(coerce_query_params: true)
    header "Content-Type", "application/json"
    get "/search/apps", {"per_page" => "10", "query" => "cloudnasium"}
    assert_equal 200, last_response.status
  end

  it "still raises an error if query param coercion is not possible" do
    @app = new_rack_app(coerce_query_params: true)
    header "Content-Type", "application/json"
    get "/search/apps", {"per_page" => "foo", "query" => "cloudnasium"}
    assert_equal 400, last_response.status
    assert_match /invalid request/i, last_response.body
  end

  private

  def new_rack_app(options = {})
    options = {
      schema: JSON.parse(File.read("./test/data/schema.json"))
    }.merge(options)
    Rack::Builder.new {
      use Committee::Middleware::RequestValidation, options
      run lambda { |_|
        [200, {}, []]
      }
    }
  end
end
