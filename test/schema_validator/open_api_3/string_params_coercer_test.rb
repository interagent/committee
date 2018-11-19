require_relative "../../test_helper"

describe Committee::SchemaValidator::OpenAPI3::StringParamsCoercer do
  before do
    path = '/string_params_coercer'
    method = 'get'
    @operation_object = open_api_3_schema.operation_object(path, method)
    @validator_option = Committee::SchemaValidator::Option.new({}, open_api_3_schema, :open_api_3)
  end

  it "doesn't coerce params not in the schema" do
    check_convert("onwer", "admin", "admin")
  end

  it "skips values for string param" do
    check_convert("string_1", "foo", "foo")
  end

  it "coerces valid values for boolean param" do
    key = "boolean_1"
    check_convert(key, "true", true)
    check_convert(key, "false", false)
    check_convert(key, "1", true)
    check_convert(key, "0", false)
  end

  it "skips invalid values for boolean param" do
    key = "boolean_1"
    check_convert(key, "foo", "foo")
  end

  it "coerces valid values for integer param" do
    check_convert("integer_1", "3", 3)
  end

  it "skips invalid values for integer param" do
    key = "integer_1"
    check_convert(key, "3.5", "3.5")
    check_convert(key, "false", "false")
    check_convert(key, "", "")
  end

  it "coerces valid values for number param" do
    key = "number_1"
    check_convert(key, "3", 3.0)
    check_convert(key, "3.5", 3.5)
  end

  it "skips invalid values for number param" do
    check_convert("number_1", "false", "false")
  end

  it "coerces valid values for null param" do
    check_convert("number_1", "", nil)
  end

  # TODO: support recursive
=begin
  it "pass array property" do
    params = {
        "array_property" => [
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
                "per_page" => "1",
                "nested_coercer_object" => {
                    "update_time" => "2016-04-01T16:00:00.000+09:00",
                    "threshold" => "1.5"
                },
                "nested_no_coercer_object" => {
                    "per_page" => "1",
                    "threshold" => "1.5"
                },
                "nested_coercer_array" => [
                    {
                        "update_time" => "2016-04-01T16:00:00.000+09:00",
                        "threshold" => "1.5"
                    }
                ],
                "nested_no_coercer_array" => [
                    {
                        "per_page" => "1",
                        "threshold" => "1.5"
                    }
                ]
            },
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
                "per_page" => "1",
                "threshold" => "1.5"
            },
            {
                "threshold" => "1.5",
                "per_page" => "1"
            }
        ],
    }
    call(params, coerce_recursive: true)

    first_data = params["array_property"][0]
    assert_kind_of String, first_data["update_time"]
    assert_kind_of Integer, first_data["per_page"]

    second_data = params["array_property"][1]
    assert_kind_of String, second_data["update_time"]
    assert_kind_of Integer, second_data["per_page"]
    assert_kind_of Float, second_data["threshold"]

    third_data = params["array_property"][1]
    assert_kind_of Integer, third_data["per_page"]
    assert_kind_of Float, third_data["threshold"]

    assert_kind_of String, first_data["nested_coercer_object"]["update_time"]
    assert_kind_of Float, first_data["nested_coercer_object"]["threshold"]

    assert_kind_of Integer, first_data["nested_no_coercer_object"]["per_page"]
    assert_kind_of Float, first_data["nested_no_coercer_object"]["threshold"]

    assert_kind_of String, first_data["nested_coercer_array"].first["update_time"]
    assert_kind_of Float, first_data["nested_coercer_array"].first["threshold"]

    assert_kind_of Integer, first_data["nested_no_coercer_array"].first["per_page"]
    assert_kind_of Float, first_data["nested_no_coercer_array"].first["threshold"]
  end
=end

  private

  def check_convert(key, before_value, after_value)
    data = {key => before_value}
    call(data)

    if !after_value.nil?
      assert_equal(data[key], after_value)
    else
      assert_nil(data[key])
    end
  end

  def call(data)
    Committee::SchemaValidator::OpenAPI3::StringParamsCoercer.new(data, @operation_object, @validator_option).call!
  end
end
