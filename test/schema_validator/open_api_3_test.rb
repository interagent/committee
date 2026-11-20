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

  describe "empty JSON responses" do
    [
      ['/characters', '', '{}'],
      ['/validate_response_array', [], ['[]']],
    ].each do |path, empty_body, valid_body|
      it "rejects an empty JSON body for #{path} while accepting an encoded empty value" do
        validator = validator_for(path, 'GET')
        headers = { 'Content-Type' => 'application/json' }

        assert_silent { validator.response_validate(200, headers, valid_body) }
        assert_raises(JSON::ParserError) { validator.response_validate(200, headers, empty_body) }
      end
    end

    it "preserves empty non-JSON response bodies" do
      validator = validator_for('/csv', 'GET')

      assert_silent { validator.response_validate(200, { 'Content-Type' => 'text/csv' }, '') }
    end

    it "lets custom parsers handle empty JSON response bodies" do
      parsed_body = nil
      parser = ->(body) { parsed_body = body; {} }

      validator_for('/characters', 'GET').response_validate(200, { 'Content-Type' => 'application/json' }, '', false, parser)

      assert_equal '', parsed_body
    end
  end
end
