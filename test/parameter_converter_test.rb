require_relative "test_helper"

require "stringio"

describe Committee::RequestValidator do
  before do
    @schema = JsonSchema.parse!(hyper_schema_data)
    @schema.expand_references!
    # POST /apps/:id
    @link = @link = @schema.properties["app"].links[0]
  end

  it "pass datetime string" do
    params = { "update_time" => "2016-04-01T16:00:00.000+09:00"}
    converted_params = call(params)

    assert_kind_of DateTime, converted_params["update_time"]
  end

  it "pass invalid datetime string, not convert" do
    params = { "update_time" => "llmfllmf"}
    converted_params = call(params)

    assert_nil converted_params["update_time"]
  end

  private

  def call(params)
    link = Committee::Drivers::HyperSchema::Link.new(@link)
    Committee::ParameterConverter.new(params, link.schema).convert!
  end
end
