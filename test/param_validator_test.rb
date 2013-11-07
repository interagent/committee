require_relative "test_helper"

describe Rack::Committee::ParamValidator do
  before do
    data = MultiJson.decode(File.read("./test/schema.json"))
    @link_schema = data["definitions"]["app-transfer"]["links"][0]
  end

  it "passes through a valid request" do
    params = {
      "app" => "www",
      "recipient" => "owner@heroku.com",
    }
    Rack::Committee::ParamValidator.new(params, @link_schema).call
  end

  it "detects a missing parameter" do
    message = "Missing params: app, recipient."
    assert_raises(Rack::Committee::InvalidParams) do
      Rack::Committee::ParamValidator.new({}, @link_schema).call
    end
  end

  it "detects an extraneous parameter" do
    params = {
      "cloud" => "production"
    }
    message = "Unknown params: cloud."
    assert_raises(Rack::Committee::InvalidParams, message) do
      Rack::Committee::ParamValidator.new(params, @link_schema).call
    end
  end
end
