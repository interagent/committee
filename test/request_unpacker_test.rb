# frozen_string_literal: true

require "test_helper"

describe Committee::RequestUnpacker do
  it "unpacks JSON on Content-Type: application/json" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new
    assert_equal([{ "x" => "y" }, false], unpacker.unpack_request_params(request))
  end

  it "unpacks JSON on Content-Type: application/vnd.api+json" do
    env = {
      "CONTENT_TYPE" => "application/vnd.api+json",
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new
    assert_equal([{ "x" => "y" }, false], unpacker.unpack_request_params(request))
  end

  it "unpacks JSON on no Content-Type" do
    env = {
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new
    assert_equal([{ "x" => "y" }, false], unpacker.unpack_request_params(request))
  end

  it "doesn't unpack JSON on application/x-ndjson" do
    env = {
      "CONTENT_TYPE" => "application/x-ndjson",
      "rack.input"   => StringIO.new('{"x":"y"}\n{"a":"b"}'),
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new
    assert_equal([{}, false], unpacker.unpack_request_params(request))
  end

  it "doesn't unpack JSON under other Content-Types" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new('{"x":"y"}'),
      }
      request = Rack::Request.new(env)
      unpacker = Committee::RequestUnpacker.new
      assert_equal([{}, false], unpacker.unpack_request_params(request))
    end
  end

  it "unpacks JSON under other Content-Types with optimistic_json" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new('{"x":"y"}'),
      }
      request = Rack::Request.new(env)
      unpacker = Committee::RequestUnpacker.new(optimistic_json: true)
      assert_equal([{ "x" => "y" }, false], unpacker.unpack_request_params(request))
    end
  end

  it "returns {} when unpacking non-JSON with optimistic_json" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new('x=y&foo=42'),
      }
      request = Rack::Request.new(env)
      unpacker = Committee::RequestUnpacker.new(optimistic_json: true)
      assert_equal([{}, false], unpacker.unpack_request_params(request))
    end
  end

  it "unpacks an empty hash on an empty request body" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new(""),
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new
    assert_equal([{}, false], unpacker.unpack_request_params(request))
  end

  it "doesn't unpack form params" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new("x=y"),
      }
      request = Rack::Request.new(env)
      unpacker = Committee::RequestUnpacker.new
      assert_equal([{}, false], unpacker.unpack_request_params(request))
    end
  end

  it "unpacks form params with allow_form_params" do
    %w[application/x-www-form-urlencoded multipart/form-data].each do |content_type|
      env = {
        "CONTENT_TYPE" => content_type,
        "rack.input"   => StringIO.new("x=y"),
      }
      request = Rack::Request.new(env)
      unpacker = Committee::RequestUnpacker.new(allow_form_params: true)
      assert_equal([{ "x" => "y" }, true], unpacker.unpack_request_params(request))
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
      unpacker = Committee::RequestUnpacker.new(allow_form_params: true, allow_query_params: true)
      assert_equal([ { "x" => "y"}, true], unpacker.unpack_request_params(request))
    end
  end

  it "unpacks query params with allow_query_params" do
    env = {
      "rack.input"   => StringIO.new(""),
      "QUERY_STRING" => "a=b"
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new(allow_query_params: true)
    assert_equal({ "a" => "b" }, unpacker.unpack_query_params(request))
  end

  it "errors if JSON is not an object" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new('[2]'),
    }
    request = Rack::Request.new(env)
    assert_raises(Committee::BadRequest) do
      Committee::RequestUnpacker.new.unpack_request_params(request)
    end
  end

  it "errors on an unknown Content-Type" do
    env = {
      "CONTENT_TYPE" => "application/whats-this",
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new
    assert_equal([{}, false], unpacker.unpack_request_params(request))
  end

  # this is mostly here for line coverage
  it "unpacks JSON containing an array" do
    env = {
      "rack.input" => StringIO.new('{"x":[]}'),
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new
    assert_equal([{ "x" => [] }, false], unpacker.unpack_request_params(request))
  end

  it "unpacks http header" do
    env = {
      "HTTP_FOO_BAR" => "some header value",
      "rack.input"   => StringIO.new(""),
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new({ allow_header_params: true })
    assert_equal({ "FOO-BAR" => "some header value" }, unpacker.unpack_headers(request))
  end

  it "includes request body when`use_get_body` is true" do
    env = {
        "rack.input" => StringIO.new('{"x":1, "y":2}'),
        "REQUEST_METHOD" => "GET",
        "QUERY_STRING"=>"data=value&x=aaa",
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new({ allow_query_params: true, allow_get_body: true })
    assert_equal([{ 'x' => 1, 'y' => 2 }, false], unpacker.unpack_request_params(request))
  end

  it "doesn't include request body when `use_get_body` is false" do
    env = {
        "rack.input" => StringIO.new('{"x":1, "y":2}'),
        "REQUEST_METHOD" => "GET",
        "QUERY_STRING"=>"data=value&x=aaa",
    }
    request = Rack::Request.new(env)
    unpacker = Committee::RequestUnpacker.new({ allow_query_params: true, use_get_body: false })
    assert_equal({ 'data' => 'value', 'x' => 'aaa' }, unpacker.unpack_query_params(request))
  end
end
