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
    post "/apps", MultiJson.encode(params)
    assert_equal 200, last_response.status
  end

  it "detects an invalid request" do
    @app = new_rack_app
    header "Content-Type", "application/json"
    params = {
      "name" => 1
    }
    post "/apps", MultiJson.encode(params)
    assert_equal 400, last_response.status
    assert_match /invalid request/i, last_response.body
  end

  it "detects an invalid Content-Type" do
    @app = new_rack_app
    header "Content-Type", "application/whats-this"
    params = {
      "name" => "cloudnasium"
    }
    post "/apps", MultiJson.encode(params)
    assert_equal 400, last_response.status
    assert_match /unsupported content-type/i, last_response.body
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
    post "/v1/apps", MultiJson.encode(params)
    assert_equal 200, last_response.status
  end

  it "warns when sending a deprecated string" do
    mock(Committee).warn_deprecated.with_any_args
    @app = new_rack_app(schema: File.read("./test/data/schema.json"))
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", MultiJson.encode(params)
    assert_equal 200, last_response.status
  end

  private

  def new_rack_app(options = {})
    options = {
      schema: MultiJson.decode(File.read("./test/data/schema.json"))
    }.merge(options)
    Rack::Builder.new {
      use Committee::Middleware::RequestValidation, options
      run lambda { |_|
        [200, {}, []]
      }
    }
  end
end
