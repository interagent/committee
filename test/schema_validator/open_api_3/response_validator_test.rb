require_relative "../../test_helper"

describe Committee::SchemaValidator::OpenAPI3::ResponseValidator do
  before do
    @status = 200
    @headers = {
      "Content-Type" => "application/json"
    }
    @data = {"string" => "Honoka.Kousaka"}

    @path = '/validate'
    @method = 'post'
    @validator_option = Committee::SchemaValidator::Option.new({}, open_api_3_schema, :open_api_3)
  end

  it "passes through a valid response" do
    call_response_validator
  end

  it "passes through a valid response with Content-Type options" do
    @headers = { "Content-Type" => "application/json; charset=utf-8" }
    call_response_validator
  end

  it "passes through a valid response with no registered Content-Type with strict = false" do
    @headers = { "Content-Type" => "application/xml" }
    call_response_validator
  end

  it "passes through a valid response with no registered Content-Type with strict = true" do
    @headers = { "Content-Type" => "application/xml" }
    assert_raises(Committee::InvalidResponse) {
      call_response_validator(true)
    }
  end

  it "passes through a valid response with no Content-Type" do
    @headers = {}
    call_response_validator
  end

  it "passes through a valid response with no Content-Type with strict option" do
    @headers = {}
    assert_raises(Committee::InvalidResponse) {
      call_response_validator(true)
    }
  end

  it "passes through a valid list response" do
    @path = '/validate_response_array'
    @method = 'get'
    @data = ["Mari.Ohara"]
    call_response_validator
  end

  it "passes through a 204 No Content response" do
    @status, @headers, @data = 204, {}, nil
    call_response_validator
  end

  private

  def call_response_validator(strict = false)
    @operation_object = open_api_3_schema.operation_object(@path, @method)
    Committee::SchemaValidator::OpenAPI3::ResponseValidator.
        new(@operation_object, @validator_option).
        call(@status, @headers, @data, strict)
  end
end
