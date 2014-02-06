require_relative "test_helper"

describe Committee::ParamValidator do
  before do
    @schema = Committee::Schema.new(File.read("./test/data/schema.json"))
    # POST /account/app-transfers
    @link_schema = @schema["app-transfer"]["links"][0]
  end

  it "passes through a valid request" do
    params = {
      "app" => "heroku-api",
      "recipient" => "owner@heroku.com",
    }
    Committee::ParamValidator.new(params, @schema, @link_schema).call
  end

  it "detects a missing parameter" do
    e = assert_raises(Committee::InvalidParams) do
      Committee::ParamValidator.new({}, @schema, @link_schema).call
    end
    message = "Require params: app, recipient."
    assert_equal message, e.message
  end

  it "detects an extraneous parameter" do
    params = {
      "app" => "heroku-api",
      "cloud" => "production",
      "recipient" => "owner@heroku.com",
    }
    e = assert_raises(Committee::InvalidParams) do
      Committee::ParamValidator.new(params, @schema, @link_schema).call
    end
    message = "Unknown params: cloud."
    assert_equal message, e.message
  end

  it "detects a parameter of the wrong type" do
    params = {
      "app" => "heroku-api",
      "recipient" => 123,
    }
    e = assert_raises(Committee::InvalidParams) do
      Committee::ParamValidator.new(params, @schema, @link_schema).call
    end
    message = %{Invalid type for key "recipient": expected 123 to be ["string"].}
    assert_equal message, e.message
  end

  it "detects a parameter of the wrong format" do
    params = {
      "app" => "heroku-api",
      "recipient" => "not-email",
    }
    e = assert_raises(Committee::InvalidParams) do
      Committee::ParamValidator.new(params, @schema, @link_schema).call
    end
    message = %{Invalid format for key "recipient": expected "not-email" to be "email".}
    assert_equal message, e.message
  end

  it "detects a parameter of the wrong pattern" do
    params = {
      "name" => "%@!"
    }
    link_schema = @schema["app"]["links"][0]
    e = assert_raises(Committee::InvalidParams) do
      Committee::ParamValidator.new(params, @schema, link_schema).call
    end
    message = %{Invalid pattern for key "name": expected %@! to match "(?-mix:^[a-z][a-z0-9-]{3,30}$)".}
    assert_equal message, e.message
  end

  it "passes an array parameter" do
    params = {
      "updates" => [
        { "name" => "bamboo", "state" => "private" },
        { "name" => "cedar", "state" => "public" },
      ]
    }
    link_schema = @schema["stack"]["links"][2]
    Committee::ParamValidator.new(params, @schema, link_schema).call
  end

  it "detects an array item with a parameter of the wrong type" do
    params = {
      "updates" => [
        { "name" => "bamboo", "state" => 123 },
      ]
    }
    link_schema = @schema["stack"]["links"][2]
    e = assert_raises(Committee::InvalidParams) do
      Committee::ParamValidator.new(params, @schema, link_schema).call
    end
    message = %{Invalid type for key "state": expected 123 to be ["string"].}
    assert_equal message, e.message
  end
end
