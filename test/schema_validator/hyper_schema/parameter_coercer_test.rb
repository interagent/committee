# frozen_string_literal: true

require "test_helper"

describe Committee::SchemaValidator::HyperSchema::ParameterCoercer do
  before do
    @schema = JsonSchema.parse!(hyper_schema_data)
    @schema.expand_references!
    # POST /apps/:id
    @link = @schema.properties["app"].links[0]
  end

  it "pass datetime string" do
    params = { "update_time" => "2016-04-01T16:00:00.000+09:00"}
    call(params, coerce_date_times: true)

    assert_kind_of DateTime, params["update_time"]
  end

  it "don't change object type" do
    params = HashLikeObject.new
    params["update_time"] = "2016-04-01T16:00:00.000+09:00"
    call(params, coerce_date_times: true)

    assert_kind_of DateTime, params["update_time"]
    assert_kind_of HashLikeObject, params
  end

  it "pass invalid datetime string, not convert" do
    invalid_datetime = "llmfllmf"
    params = { "update_time" => invalid_datetime}
    call(params, coerce_date_times: true)

    assert_equal invalid_datetime, params["update_time"]
  end

  it "pass array property" do
    params = {
        "array_property" => [
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
                "per_page" => 1,
                "nested_coercer_object" => {
                    "update_time" => "2016-04-01T16:00:00.000+09:00",
                    "threshold" => 1.5
                },
                "nested_no_coercer_object" => {
                    "per_page" => 1,
                    "threshold" => 1.5
                },
                "nested_coercer_array" => [
                    {
                        "update_time" => "2016-04-01T16:00:00.000+09:00",
                        "threshold" => 1.5
                    }
                ],
                "nested_no_coercer_array" => [
                    {
                        "per_page" => 1,
                        "threshold" => 1.5
                    }
                ]
            },
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
                "per_page" => 1,
                "threshold" => 1.5
            },
            {
                "threshold" => 1.5,
                "per_page" => 1
            }
        ],
    }
    call(params, coerce_date_times: true, coerce_recursive: true)

    first_data = params["array_property"][0]
    assert_kind_of DateTime, first_data["update_time"]
    assert_kind_of Integer, first_data["per_page"]

    second_data = params["array_property"][1]
    assert_kind_of DateTime, second_data["update_time"]
    assert_kind_of Integer, second_data["per_page"]
    assert_kind_of Float, second_data["threshold"]

    third_data = params["array_property"][1]
    assert_kind_of Integer, third_data["per_page"]
    assert_kind_of Float, third_data["threshold"]

    assert_kind_of DateTime, first_data["nested_coercer_object"]["update_time"]
    assert_kind_of Float, first_data["nested_coercer_object"]["threshold"]

    assert_kind_of Integer, first_data["nested_no_coercer_object"]["per_page"]
    assert_kind_of Float, first_data["nested_no_coercer_object"]["threshold"]

    assert_kind_of DateTime, first_data["nested_coercer_array"].first["update_time"]
    assert_kind_of Float, first_data["nested_coercer_array"].first["threshold"]

    assert_kind_of Integer, first_data["nested_no_coercer_array"].first["per_page"]
    assert_kind_of Float, first_data["nested_no_coercer_array"].first["threshold"]
  end

  private

  class HashLikeObject < Hash; end

  def call(params, options={})
    link = Committee::Drivers::HyperSchema::Link.new(@link)
    Committee::SchemaValidator::HyperSchema::ParameterCoercer.new(params, link.schema, options).call!
  end
end
