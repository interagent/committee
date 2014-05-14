require_relative "../test_helper"

describe Committee::Middleware::RequestValidation do
  include Rack::Test::Methods

  def app
    @app
  end

  it "passes through a valid request" do
    @app = new_rack_app
    params = {
      "app" => "heroku-api",
      "recipient" => "owner@heroku.com",
    }
    header "Content-Type", "application/json"
    post "/account/app-transfers", MultiJson.encode(params)
    assert_equal 200, last_response.status
  end

  it "detects an invalid Content-Type" do
    @app = new_rack_app
    header "Content-Type", "application/whats-this"
    post "/account/app-transfers", "{}"
    assert_equal 400, last_response.status
  end

  it "rescues JSON errors" do
    @app = new_rack_app
    header "Content-Type", "application/json"
    post "/account/app-transfers", "{x:y}"
    assert_equal 400, last_response.status
    assert_match /valid json/i, last_response.body
  end

  it "takes a prefix" do
    @app = new_rack_app(prefix: "/v1")
    params = {
      "app" => "heroku-api",
      "recipient" => "owner@heroku.com",
    }
    header "Content-Type", "application/json"
    post "/v1/account/app-transfers", MultiJson.encode(params)
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
