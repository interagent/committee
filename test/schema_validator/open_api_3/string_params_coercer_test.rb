require_relative "../../test_helper"

describe Committee::SchemaValidator::OpenAPI3::StringParamsCoercer do
  before do
    path = '/string_params_coercer'
    method = 'get'
    @operation_object = open_api_3_schema.operation_object(path, method)
    @validator_option = Committee::SchemaValidator::Option.new({}, open_api_3_schema, :open_api_3)
  end

  def nested_array
    return [
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
    ]
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

  describe "array" do
    it "normal array" do
      params = {
          "normal_array" => [
              "1"
          ]
      }
      call(params)

      normal_array = params["normal_array"]
      assert_kind_of Integer, normal_array[0]
    end

    it "nested array" do
      @validator_option = Committee::SchemaValidator::Option.new({coerce_recursive: true, coerce_date_times: false}, open_api_3_schema, :open_api_3)

      params = { "nested_array" => nested_array }
      call(params)

      nested_array = params["nested_array"]
      first_data = nested_array[0]
      assert_kind_of String, first_data["update_time"]
      assert_kind_of Integer, first_data["per_page"]

      second_data = nested_array[1]
      assert_kind_of String, second_data["update_time"]
      assert_kind_of Integer, second_data["per_page"]
      assert_kind_of Float, second_data["threshold"]

      third_data = nested_array[2]
      assert_kind_of Integer, third_data["per_page"]
      assert_kind_of Float, third_data["threshold"]

      assert_kind_of String, first_data["nested_coercer_object"]["update_time"]
      assert_kind_of Float, first_data["nested_coercer_object"]["threshold"]

      assert_kind_of String, first_data["nested_no_coercer_object"]["per_page"]
      assert_kind_of String, first_data["nested_no_coercer_object"]["threshold"]

      assert_kind_of String, first_data["nested_coercer_array"].first["update_time"]
      assert_kind_of Float, first_data["nested_coercer_array"].first["threshold"]

      assert_kind_of String, first_data["nested_no_coercer_array"].first["per_page"]
      assert_kind_of String, first_data["nested_no_coercer_array"].first["threshold"]
    end
  end

  describe "coerce_parameter" do
    before do
      @path = '/string_params_coercer'
      @method = 'get'
    end

    it "pass datetime string" do
      params = { "datetime_string" => "2016-04-01T16:00:00.000+09:00"}
      parameter_coercer_call(params, coerce_date_times: true)

      assert_kind_of DateTime, params["datetime_string"]
    end

    it "pass invalid datetime string, not convert" do
      invalid_datetime = "llmfllmf"
      params = { "datetime_string" => invalid_datetime}
      parameter_coercer_call(params, coerce_date_times: true)

      assert_equal invalid_datetime, params["datetime_string"]
    end

    it "don't change object type" do
      params = HashLikeObject.new
      params["datetime_string"] = "2016-04-01T16:00:00.000+09:00"
      parameter_coercer_call(params, coerce_date_times: true)

      assert_kind_of DateTime, params["datetime_string"]
      assert_kind_of HashLikeObject, params
    end

    it "nested array" do
      params = { "nested_array" => nested_array }
      parameter_coercer_call(params, coerce_recursive: true, coerce_date_times: true)

      nested_array = params["nested_array"]
      first_data = nested_array[0]
      assert_kind_of DateTime, first_data["update_time"]
      assert_kind_of Integer, first_data["per_page"]

      second_data = nested_array[1]
      assert_kind_of DateTime, second_data["update_time"]
      assert_kind_of Integer, second_data["per_page"]
      assert_kind_of Float, second_data["threshold"]

      third_data = nested_array[2]
      assert_kind_of Integer, third_data["per_page"]
      assert_kind_of Float, third_data["threshold"]

      assert_kind_of DateTime, first_data["nested_coercer_object"]["update_time"]
      assert_kind_of Float, first_data["nested_coercer_object"]["threshold"]

      assert_kind_of String, first_data["nested_no_coercer_object"]["per_page"]
      assert_kind_of String, first_data["nested_no_coercer_object"]["threshold"]

      assert_kind_of DateTime, first_data["nested_coercer_array"].first["update_time"]
      assert_kind_of Float, first_data["nested_coercer_array"].first["threshold"]

      assert_kind_of String, first_data["nested_no_coercer_array"].first["per_page"]
      assert_kind_of String, first_data["nested_no_coercer_array"].first["threshold"]
    end
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

  def call(data)
    @operation_object.coerce_query_parameter(data, @validator_option)
  end

  def parameter_coercer_call(params, options={})
    @validator_option = Committee::SchemaValidator::Option.new(options, open_api_3_schema, :open_api_3)
    @operation_object.coerce_parameter(params, @validator_option)
  end
end
