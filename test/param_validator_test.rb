require_relative "test_helper"

describe Rack::Committee::ParamValidator do
  it "passes through a valid request" do
    params = {
      "app" => "www",
      "recipient" => "owner@heroku.com",
    }
    Rack::Committee::ParamValidator.new(params, link_schema).call
  end

  it "detects a missing parameter" do
    message = "Missing params: app, recipient."
    assert_raises(Rack::Committee::InvalidParams) do
      Rack::Committee::ParamValidator.new({}, link_schema).call
    end
  end

  it "detects an extraneous parameter" do
    params = {
      "cloud" => "production"
    }
    message = "Unknown params: cloud."
    assert_raises(Rack::Committee::InvalidParams, message) do
      Rack::Committee::ParamValidator.new(params, link_schema).call
    end
  end

  def link_schema
    {
      "description"  => "Create a new app transfer.",
      "href"         => "/account/app-transfers",
      "method"       => "POST",
      "rel"          => "create",
      "schema"       => {
        "properties" => {
          "app"       => { "$ref" => "/schema/app#/definitions/identity" },
          "recipient" => { "$ref" => "/schema/account#/definitions/identity" }
        },
        "required" => ["app","recipient"]
      },
      "title"        => "Create"
    }
  end
end
