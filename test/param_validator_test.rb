require_relative "test_helper"

describe Rack::Committee::ParamValidator do
  before do
    @schema = Rack::Committee::Schema.new(File.read("./test/data/schema.json"))
    @link_schema = @schema["app-transfer"]["links"][0]
  end

  it "passes through a valid request" do
    params = {
      "app" => "heroku-api",
      "recipient" => "owner@heroku.com",
    }
    Rack::Committee::ParamValidator.new(params, @schema, @link_schema).call
  end

  it "detects a missing parameter" do
    message = "Missing params: app, recipient."
    assert_raises(Rack::Committee::InvalidParams, message) do
      Rack::Committee::ParamValidator.new({}, @schema, @link_schema).call
    end
  end

  it "detects an extraneous parameter" do
    params = {
      "cloud" => "production"
    }
    message = "Unknown params: cloud."
    assert_raises(Rack::Committee::InvalidParams, message) do
      Rack::Committee::ParamValidator.new(params, @schema, @link_schema).call
    end
  end

  it "detects a parameter of the wrong type" do
    params = {
      "app" => "heroku-api",
      "recipient" => 123,
    }
    message = %{Invalid type for key "recipient": expected 123 to be ["string"].}
    assert_raises(Rack::Committee::InvalidParams, message) do
      Rack::Committee::ParamValidator.new(params, @schema, @link_schema).call
    end
  end

  it "detects a parameter of the wrong format" do
    params = {
      "app" => "heroku-api",
      "recipient" => "not-email",
    }
    message = %{Invalid format for key "recipient": expected "not-email" to be "email".}
    assert_raises(Rack::Committee::InvalidParams, message) do
      Rack::Committee::ParamValidator.new(params, @schema, @link_schema).call
    end
  end

  it "detects a parameter of the wrong pattern" do
    params = {
      "name" => "%@!"
    }
    message = %{Invalid pattern for key "name": expected %@! to match (?-mix:^[a-z][a-z0-9-]{3,30}$).}
    link_schema = @schema["app"]["links"][0]
    assert_raises(Rack::Committee::InvalidParams, message) do
      Rack::Committee::ParamValidator.new(params, @schema, link_schema).call
    end
  end
end
