# frozen_string_literal: true

require "test_helper"

describe Committee::SchemaValidator::HyperSchema::StringParamsCoercer do
  before do
    @schema = JsonSchema.parse!(hyper_schema_data)
    @schema.expand_references!
    # GET /search/apps
    @link = @schema.properties["app"].links[5]
  end

  it "doesn't coerce params not in the schema" do
    check_convert("owner", "admin", "admin")
  end

  it "skips values for string param" do
    check_convert("name", "foo", "foo")
  end

  it "coerces valid values for boolean param" do
    check_convert("deleted", "true", true)
    check_convert("deleted", "false", false)
    check_convert("deleted", "1", true)
    check_convert("deleted", "0", false)
  end

  it "skips invalid values for boolean param" do
    check_convert("deleted", "foo", "foo")
  end

  it "coerces valid values for integer param" do
    check_convert("per_page", "3", 3)
  end

  it "skips invalid values for integer param" do
    check_convert("per_page", "3.5", "3.5")
    check_convert("per_page", "false", "false")
    check_convert("per_page", "", "")
  end

  it "coerces valid values for number param" do
    check_convert("threshold", "3", 3.0)
    check_convert("threshold", "3.5", 3.5)
  end

  it "skips invalid values for number param" do
    check_convert("threshold", "false", "false")
  end

  it "coerces valid values for null param" do
    check_convert("threshold", "", nil)
  end

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

  def call(data, options={})
    Committee::SchemaValidator::HyperSchema::StringParamsCoercer.new(data, @link.schema, options).call!
  end
end
