require_relative "test_helper"

require "stringio"

describe Committee::RequestUnpacker do
  it "unpacks JSON on Content-Type: application/json" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request).call
    assert_equal({ "x" => "y" }, params)
  end

  it "unpacks JSON on no Content-Type" do
    env = {
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request).call
    assert_equal({ "x" => "y" }, params)
  end

  it "doesn't unpack JSON under other Content-Types" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new('{"x":"y"}'),
      }
      request = Rack::Request.new(env)
      params, _ = Committee::RequestUnpacker.new(request).call
      assert_equal({}, params)
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
      assert_equal({ "x" => "y" }, params)
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
      assert_equal({}, params)
    end
  end

  it "unpacks an empty hash on an empty request body" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new(""),
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request).call
    assert_equal({}, params)
  end

  it "doesn't unpack form params" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new("x=y"),
      }
      request = Rack::Request.new(env)
      params, _ = Committee::RequestUnpacker.new(request).call
      assert_equal({}, params)
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
      assert_equal({ "x" => "y" }, params)
    end
  end

  it "coerces form params with coerce_form_params and a schema" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      schema = JsonSchema::Schema.new
      schema.properties = { "x" => JsonSchema::Schema.new }
      schema.properties["x"].type = ["integer"]

      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new("x=1"),
      }
      request = Rack::Request.new(env)
      params, _ = Committee::RequestUnpacker.new(
        request,
        allow_form_params: true,
        coerce_form_params: true,
        schema: schema
      ).call
      assert_equal({ "x" => 1 }, params)
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
      assert_equal({ "x" => "y", "a" => "b" }, params)
    end
  end

  it "unpacks query params with allow_query_params" do
    env = {
      "rack.input"   => StringIO.new(""),
      "QUERY_STRING" => "a=b"
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request, allow_query_params: true).call
    assert_equal({ "a" => "b" }, params)
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
    assert_equal({}, params)
  end

  # this is mostly here for line coverage
  it "unpacks JSON containing an array" do
    env = {
      "rack.input" => StringIO.new('{"x":[]}'),
    }
    request = Rack::Request.new(env)
    params, _ = Committee::RequestUnpacker.new(request).call
    assert_equal({ "x" => [] }, params)
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
end
