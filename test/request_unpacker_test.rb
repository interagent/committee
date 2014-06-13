require_relative "test_helper"

require "stringio"

describe Committee::RequestUnpacker do
  it "unpacks JSON on Content-Type: application/json" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    params = Committee::RequestUnpacker.new(request).call
    assert_equal({ "x" => "y" }, params)
  end

  it "unpacks JSON on no Content-Type" do
    env = {
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    request = Rack::Request.new(env)
    params = Committee::RequestUnpacker.new(request).call
    assert_equal({ "x" => "y" }, params)
  end

  it "unpacks an empty hash on an empty request body" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new(""),
    }
    request = Rack::Request.new(env)
    params = Committee::RequestUnpacker.new(request).call
    assert_equal({}, params)
  end

  it "unpacks params on Content-Type: application/x-www-form-urlencoded" do
    env = {
      "CONTENT_TYPE" => "application/x-www-form-urlencoded",
      "rack.input"   => StringIO.new("x=y"),
    }
    request = Rack::Request.new(env)
    params = Committee::RequestUnpacker.new(request).call
    assert_equal({ "x" => "y" }, params)
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
    params = Committee::RequestUnpacker.new(request).call
    assert_equal({}, params)
  end
end
