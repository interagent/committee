require_relative "test_helper"

describe Committee::ParamValidation do
  include Rack::Test::Methods

  StubApp = Rack::Builder.new {
    use Committee::ParamValidation, schema: File.read("./test/data/schema.json")
    run lambda { |_|
      [200, {}, []]
    }
  }

  def app
    StubApp
  end

  before do
    header "Content-Type", "application/json"
  end

  it "detects an invalid Content-Type" do
    header "Content-Type", "application/whats-this"
    post "/account/app-transfers", "{}"
    assert_equal 400, last_response.status
  end

  it "passes through a valid request" do
    params = {
      "app" => "heroku-api",
      "recipient" => "owner@heroku.com",
    }
    post "/account/app-transfers", MultiJson.encode(params)
    assert_equal 200, last_response.status
  end

  it "detects a missing parameter" do
    post "/account/app-transfers", "{}"
    assert_equal 422, last_response.status
  end

  it "detects an extra parameter" do
    params = {
      "cloud" => "production"
    }
    post "/account/app-transfers", MultiJson.encode(params)
    assert_equal 422, last_response.status
  end
end
