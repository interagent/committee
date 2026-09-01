# frozen_string_literal: true

require "test_helper"

describe Committee::SchemaValidator::OpenAPI3 do
  before do
    @router = open_api_3_schema.build_router(schema: open_api_3_schema)
  end

  def validator_for(path, method)
    request = Rack::Request.new({ "REQUEST_METHOD" => method, "PATH_INFO" => path, "rack.input" => StringIO.new("") })
    @router.build_schema_validator(request)
  end

  describe "#operation_object" do
    it "returns the matched operation wrapper" do
      operation_object = validator_for("/validate", "POST").operation_object

      assert_kind_of Committee::SchemaValidator::OpenAPI3::OperationWrapper, operation_object
      assert_equal "/validate", operation_object.original_path
    end

    it "returns nil when the request matches no operation" do
      assert_nil validator_for("/no-such-path", "GET").operation_object
    end
  end
end
