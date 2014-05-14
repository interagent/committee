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
    assert_equal 2, e.count
    assert_equal :missing, e.on(:app)
    assert_equal :missing, e.on(:recipient)
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
    assert_equal 1, e.count
    assert_equal :bad_type, e.on(:recipient)
  end

  it "detects a parameter of the wrong format" do
    params = {
      "app" => "heroku-api",
      "recipient" => "not-email",
    }
    e = assert_raises(Committee::InvalidParams) do
      validate(params, @schema, @link_schema)
    end
    assert_equal 1, e.count
    assert_equal :bad_format, e.on(:recipient)
  end

  it "detects a parameter of the wrong pattern" do
    params = {
      "name" => "%@!"
    }
    link_schema = @schema["app"]["links"][0]
    e = assert_raises(Committee::InvalidParams) do
      validate(params, @schema, link_schema)
    end
    assert_equal 1, e.count
    assert_equal :bad_pattern, e.on(:name)
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
      assert_equal 1, e.count
      assert_equal :bad_type, e.on(:state)
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
      assert_equal 1, e.count
      assert_equal :bad_type, e.on(:flags)
    end
  end

  describe "combined errors" do
    params = {
      "app" => "%@!", # bad pattern
      "recipient" => 123, # bad type
      "cloud" => true, # extra
    }
    it "stores errors on all params" do
      e = assert_raises(Committee::InvalidParams) do
        validate(params, @schema, @link_schema)
      end
      assert_equal 3, e.count
      assert_equal :bad_pattern, e.on(:app)
      assert_equal :bad_type, e.on(:recipient)
      assert_equal :extra, e.on(:cloud)
    end
  end

  private

  def validate(params, schema, link_schema, options = {})
    Committee::ParamValidator.new(params, schema, link_schema, options).call
  end
end
