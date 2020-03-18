# frozen_string_literal: true

require "test_helper"

describe Committee::RequestUnpacker do
  it "unpacks JSON on Content-Type: application/json" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request).call
    assert_equal({ "x" => "y" }, params["body"])
  end

  it "unpacks JSON on no Content-Type" do
    env = {
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request).call
    assert_equal({ "x" => "y" }, params["body"])
  end

  it "doesn't unpack JSON under other Content-Types" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new('{"x":"y"}'),
      }
      request = Rack::Request.new(env)
      params, _ = Committee::RequestUnpacker.new(request).call
      assert_equal({}, params["body"])
    end
  end

  it "unpacks JSON under other Content-Types with optimistic_json" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new('{"x":"y"}'),
      }
      request = Rack::Request.new(env)
      params, _ = Committee::RequestUnpacker.new(request, optimistic_json: true).call
      assert_equal({ "x" => "y" }, params["body"])
    end
  end

  it "returns {} when unpacking non-JSON with optimistic_json" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new('x=y&foo=42'),
      }
      request = Rack::Request.new(env)
      params, _ = Committee::RequestUnpacker.new(request, optimistic_json: true).call
      assert_equal(nil, params["body"])
    end
  end

  it "unpacks an empty hash on an empty request body" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new(""),
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request).call
    assert_nil params["body"]
  end

  it "doesn't unpack form params" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new("x=y"),
      }
      request = Rack::Request.new(env)
      params, _ = Committee::RequestUnpacker.new(request).call
      assert_equal({}, params["body"])
    end
  end

  it "unpacks form params with allow_form_params" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new("x=y"),
      }
      request = Rack::Request.new(env)
      params, _ = Committee::RequestUnpacker.new(request, allow_form_params: true).call
      assert_equal({ "x" => "y" }, params["form_data"])
    end
  end

  it "coerces form params with coerce_form_params and a schema" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
          "CONTENT_TYPE" => content_type,
          "rack.input"   => StringIO.new("x=1"),
      }
      request = Rack::Request.new(env)

      router = hyper_schema.build_router({})
      validator = router.build_schema_validator(request)

      schema = JsonSchema::Schema.new
      schema.properties = { "x" => JsonSchema::Schema.new }
      schema.properties["x"].type = ["integer"]

      link_class = Struct.new(:schema)
      link_object = link_class.new(schema)

      validator.instance_variable_set(:@link, link_object)

      params, _ = Committee::RequestUnpacker.new(
        request,
        allow_form_params: true,
        coerce_form_params: true,
        schema_validator: validator,
      ).call
      assert_equal({ "x" => 1 }, params)
    end
  end

  it "coerces form params with coerce_form_params and an OpenAPI3 schema" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
          "CONTENT_TYPE" => content_type,
          "rack.input"   => StringIO.new("limit=20"),
          "PATH_INFO" => "/characters",
          "SCRIPT_NAME" => "",
          "REQUEST_METHOD" => "GET",
      }
      request = Rack::Request.new(env)

      router = open_api_3_schema.build_router({})
      validator = router.build_schema_validator(request)

      params, _ = Committee::RequestUnpacker.new(
          request,
          allow_form_params: true,
          coerce_form_params: true,
          schema_validator: validator,
          ).call
      # openapi3 not support coerce in request unpacker
      assert_equal({ "limit" => '20' }, params["form_data"])
    end
  end

  it "coerces error params with coerce_form_params and a OpenAPI3 schema" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
          "CONTENT_TYPE" => content_type,
          "rack.input"   => StringIO.new("limit=twenty"),
          "PATH_INFO" => "/characters",
          "SCRIPT_NAME" => "",
          "REQUEST_METHOD" => "GET",
      }
      request = Rack::Request.new(env)

      router = open_api_3_schema.build_router({})
      validator = router.build_schema_validator(request)

      params, _ = Committee::RequestUnpacker.new(
          request,
          allow_form_params: true,
          coerce_form_params: true,
          schema_validator: validator,
          ).call
      assert_equal({ "limit" => "twenty" }, params["form_data"])
    end
  end

  it "unpacks form & query params with allow_form_params and allow_query_params" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new("x=y"),
        "QUERY_STRING" => "a=b"
      }
      request = Rack::Request.new(env)
      params, _ = Committee::RequestUnpacker.new(request, allow_form_params: true, allow_query_params: true).call
      assert_equal({"body" => {}, "form_data" => {"x" => "y"}, "query" => {"a"=>"b"}}, params)
    end
  end

  it "unpacks query params with allow_query_params" do
    env = {
      "rack.input"   => StringIO.new(""),
      "QUERY_STRING" => "a=b"
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request, allow_query_params: true).call
    assert_equal({ "a" => "b" }, params["query"])
  end

  it "errors if JSON is not an object" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new('[2]'),
    }
    request = Rack::Request.new(env)
    assert_raises(Committee::BadRequest) do
      Committee::RequestUnpacker.new(request).call
    end
  end

  it "errors on an unknown Content-Type" do
    env = {
      "CONTENT_TYPE" => "application/whats-this",
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request).call
    assert_equal({"body" => {}, "form_data" => {}, "query" => {}}, params)
  end

  # this is mostly here for line coverage
  it "unpacks JSON containing an array" do
    env = {
      "rack.input" => StringIO.new('{"x":[]}'),
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request).call
    assert_equal({ "x" => [] }, params["body"])
  end

  it "unpacks http header" do
    env = {
      "HTTP_FOO_BAR" => "some header value",
      "rack.input"   => StringIO.new(""),
    }
    request = Rack::Request.new(env)
    _, headers = Committee::RequestUnpacker.new(request, { allow_header_params: true }).call
    assert_equal({ "FOO-BAR" => "some header value" }, headers)
  end

  it "includes request body when`use_get_body` is true" do
    env = {
        "rack.input" => StringIO.new('{"x":1, "y":2}'),
        "REQUEST_METHOD" => "GET",
        "QUERY_STRING"=>"data=value&x=aaa",
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request, { allow_query_params: true, allow_get_body: true }).call
    assert_equal({"body" => {"x" => 1, "y" => 2}, "form_data" => {}, "query" => {"data" => "value", "x" => "aaa"}}, params)
  end

  it "doesn't include request body when `use_get_body` is false" do
    env = {
        "rack.input" => StringIO.new('{"x":1, "y":2}'),
        "REQUEST_METHOD" => "GET",
        "QUERY_STRING"=>"data=value&x=aaa",
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request, { allow_query_params: true, use_get_body: false }).call
    assert_equal({ 'data' => 'value', 'x' => 'aaa' }, params["query"])
  end
end
