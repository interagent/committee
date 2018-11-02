require_relative "../test_helper"

describe Committee::Drivers::OpenAPI3 do
  before do
    @driver = Committee::Drivers::OpenAPI3.new
  end

  it "has a name" do
    assert_equal :open_api_3, @driver.name
  end

  it "has a schema class" do
    assert_equal Committee::Drivers::OpenAPI3::Schema, @driver.schema_class
  end

  it "override methods" do
    schema = @driver.parse(open_api_3_data)

    assert_kind_of Committee::Drivers::OpenAPI3::Schema, schema
    assert_kind_of OasParser::Definition, schema.definitions
    assert_equal @driver, schema.driver
  end

  it "defaults to coercing form parameters" do
    assert_equal true, @driver.default_coerce_form_params
  end

  it "defaults to path parameters" do
    assert_equal true, @driver.default_path_params
  end

  it "defaults to query parameters" do
    assert_equal true, @driver.default_query_params
  end
end
