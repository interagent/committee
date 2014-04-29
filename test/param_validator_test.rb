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
    validate(params, @schema, @link_schema)
  end

  it "detects a missing parameter" do
    e = assert_raises(Committee::InvalidParams) do
      validate({}, @schema, @link_schema)
    end
    message = "Require params: app, recipient."
    assert_equal message, e.message
  end

  it "doesn't error on an extraneous parameter with allow_extra" do
    params = {
      "app" => "heroku-api",
      "cloud" => "production",
      "recipient" => "owner@heroku.com",
    }
    validate(params, @schema, @link_schema, allow_extra: true)
  end

  it "detects a parameter of the wrong type" do
    params = {
      "app" => "heroku-api",
      "recipient" => 123,
    }
    e = assert_raises(Committee::InvalidParams) do
      validate(params, @schema, @link_schema)
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
      validate(params, @schema, @link_schema)
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
      validate(params, @schema, link_schema)
    end
    message = %{Invalid pattern for key "name": expected %@! to match "(?-mix:^[a-z][a-z0-9-]{3,30}$)".}
    assert_equal message, e.message
  end

  describe "complex arrays" do
    it "passes an array parameter" do
      params = {
        "updates" => [
          { "name" => "bamboo", "state" => "private" },
          { "name" => "cedar", "state" => "public" },
        ]
      }
      link_schema = @schema["stack"]["links"][2]
      validate(params, @schema, link_schema)
    end

    it "detects an array item with a parameter of the wrong type" do
      params = {
        "updates" => [
          { "name" => "bamboo", "state" => 123 },
        ]
      }
      link_schema = @schema["stack"]["links"][2]
      e = assert_raises(Committee::InvalidParams) do
        validate(params, @schema, link_schema)
      end
      message = %{Invalid type for key "state": expected 123 to be ["string"].}
      assert_equal message, e.message
    end
  end

  describe "simple arrays" do
    it "passes an array parameter" do
      params = {
        "password" => "1234",
        "flags" => [ "vip", "customer" ]
      }
      link_schema = @schema["account"]["links"][1]
      validate(params, @schema, link_schema)
    end

    it "detects an array item with a parameter of the wrong type" do
      params = {
        "password" => "1234",
        "flags" => [ "vip", "customer", 999 ]
      }
      link_schema = @schema["account"]["links"][1]
      e = assert_raises(Committee::InvalidParams) do
        validate(params, @schema, link_schema)
      end
      message = %{Invalid type for key "flags": expected 999 to be ["string"].}
      assert_equal message, e.message
    end
  end

  describe "combined errors" do
    params = {
      "app" => "%@!", # wrong format
      "recipient" => 123, # wrong type
      "cloud" => true, # extra
    }
    it "renders a multiline error" do
      e = assert_raises(Committee::InvalidParams) do
        validate(params, @schema, @link_schema)
      end
      assert_match "Invalid format for key \"app\"", e.message
      assert_match "Invalid type for key \"recipient\"", e.message
      assert_match "Unknown params: cloud", e.message
    end
  end

  private

  def validate(params, schema, link_schema, options = {})
    Committee::ParamValidator.new(params, schema, link_schema, options).call
  end
end
