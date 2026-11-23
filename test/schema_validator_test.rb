# frozen_string_literal: true

require "test_helper"

describe Committee::SchemaValidator do
  it "parses simple content types" do
    request = Rack::Request.new({ "CONTENT_TYPE" => "application/json" })
    media_type = Committee::SchemaValidator.request_media_type(request)
    assert_equal 'application/json', media_type
  end

  it "parses comma-delineated content types" do
    request = Rack::Request.new({ "CONTENT_TYPE" => "multipart/form-data, application/json" })
    media_type = Committee::SchemaValidator.request_media_type(request)
    assert_equal 'multipart/form-data', media_type
  end

  it "parses semicolon-delineated content types" do
    request = Rack::Request.new({ "CONTENT_TYPE" => "multipart/form-data; application/json" })
    media_type = Committee::SchemaValidator.request_media_type(request)
    assert_equal 'multipart/form-data', media_type
  end

  it "detects application/json as a JSON media type" do
    assert_equal true, Committee::SchemaValidator.json_media_type?("application/json")
  end

  it "detects application/problem+json with parameters as a JSON media type" do
    assert_equal true, Committee::SchemaValidator.json_media_type?("application/problem+json; charset=utf-8")
  end

  it "detects application/vnd.api+json as a JSON media type" do
    assert_equal true, Committee::SchemaValidator.json_media_type?("application/vnd.api+json")
  end

  it "does not detect application/x-ndjson as a JSON media type" do
    assert_equal false, Committee::SchemaValidator.json_media_type?("application/x-ndjson")
  end

  it "does not detect non-JSON content types as JSON media types" do
    assert_equal false, Committee::SchemaValidator.json_media_type?("test/csv")
    assert_equal false, Committee::SchemaValidator.json_media_type?(nil)
  end

  describe "sequential JSON" do
    it "recognizes complete media types and structured suffixes" do
      %w[application/jsonl application/x-ndjson application/json-seq application/geo+json-seq model/example+json-seq].each do |content_type|
        assert Committee::SchemaValidator.sequential_json_media_type?("#{content_type}; charset=utf-8")
      end
      [nil, 'application/json', 'x-application/jsonl', 'application/jsonl-extra', 'application/json-sequence', 'text/event-stream'].each do |content_type|
        refute Committee::SchemaValidator.sequential_json_media_type?(content_type)
      end
    end

    it "parses every newline-delimited JSON value in order" do
      values = [{ 'a' => 1 }, nil, false, 3, 'text', [1]]
      body = values.map { |value| JSON.generate(value) }.join("\r\n") + "\r\n"

      assert_equal values, Committee::SchemaValidator.parse_sequential_json(body, 'application/jsonl')
      assert_equal values, Committee::SchemaValidator.parse_sequential_json(body, 'application/x-ndjson')
    end

    it "rejects blank JSON Lines records" do
      ["{}\n\n{}\n", "{}\n\n", " \n"].each do |body|
        assert_raises(JSON::ParserError) { Committee::SchemaValidator.parse_sequential_json(body, 'application/jsonl') }
      end
    end

    it "parses RS-delimited pretty JSON and scalar values" do
      body = "\x1e#{JSON.pretty_generate('a' => 1)}\n\x1enull\n\x1efalse\n\x1e1\n\x1e\"text\""

      assert_equal [{ 'a' => 1 }, nil, false, 1, 'text'], Committee::SchemaValidator.parse_sequential_json(body, 'application/geo+json-seq')
    end

    it "ignores consecutive record separators rather than creating empty values" do
      assert_equal [{}, false], Committee::SchemaValidator.parse_sequential_json("\x1e\x1e{}\n\x1e\x1efalse\n", 'application/json-seq')
    end

    it "rejects JSON sequences without a leading record separator" do
      ["{}\n", "{}\x1e{}\n", " \x1e{}\n"].each do |body|
        assert_raises(JSON::ParserError) { Committee::SchemaValidator.parse_sequential_json(body, 'application/json-seq') }
      end
    end

    it "rejects potentially truncated scalar sequence records" do
      %w[1 1e1 true false null].each do |value|
        assert_raises(JSON::ParserError) { Committee::SchemaValidator.parse_sequential_json("\x1e#{value}", 'application/json-seq') }
      end
      assert_raises(JSON::ParserError) { Committee::SchemaValidator.parse_sequential_json("\x1e1\x1e{}\n", 'application/json-seq') }
      assert_equal [1, true, nil], Committee::SchemaValidator.parse_sequential_json("\x1e1\n\x1etrue \x1enull\t", 'application/json-seq')
    end

    it "maps empty sequential JSON bodies to empty arrays" do
      %w[application/jsonl application/x-ndjson application/json-seq application/geo+json-seq].each do |content_type|
        assert_equal [], Committee::SchemaValidator.parse_sequential_json('', content_type)
      end
    end
  end

  it "parses +json responses in the HyperSchema validator" do
    schema = Committee::Drivers::OpenAPI2::Driver.new.parse(open_api_2_data)
    validator_option = Committee::SchemaValidator::Option.new({ parse_response_by_content_type: true }, schema, :hyper_schema)
    router = Committee::SchemaValidator::HyperSchema::Router.new(schema, validator_option)
    request = Rack::Request.new({ "REQUEST_METHOD" => "GET", "PATH_INFO" => "/api/pets", "rack.input" => StringIO.new("") })
    validator = Committee::SchemaValidator::HyperSchema.new(router, request, validator_option)

    validator.link.media_type = "application/vnd.api+json"

    validator.response_validate(200, { "Content-Type" => "application/vnd.api+json" }, [JSON.generate([ValidPet])])
  end

  it "builds prefix regexp with a path segment boundary" do
    regexp = Committee::SchemaValidator.build_prefix_regexp("/v1")

    assert regexp.match?("/v1")
    assert regexp.match?("/v1/characters")
    refute regexp.match?("/v11/characters")
  end

  ["/v1/", "/"].each do |prefix|
    it "preserves the path's leading slash after removing prefix #{prefix.inspect}" do
      regexp = Committee::SchemaValidator.build_prefix_regexp(prefix)

      assert_equal "/characters", "#{prefix}characters".sub(regexp, "")
      assert_equal "/", prefix.sub(regexp, "")
      refute regexp.match?("/v11/characters") unless prefix == "/"
    end
  end
end
