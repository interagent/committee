require_relative "test_helper"

describe Rack::Committee::RequestUnpacker do
  it "unpacks JSON on Content-Type: application/json" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    params = Rack::Committee::RequestUnpacker.new(env).call
    assert_equal({ "x" => "y" }, params)
  end

  it "unpacks JSON on no Content-Type" do
    env = {
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    params = Rack::Committee::RequestUnpacker.new(env).call
    assert_equal({ "x" => "y" }, params)
  end

  it "unpacks an empty hash on an empty request body" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new(""),
    }
    params = Rack::Committee::RequestUnpacker.new(env).call
    assert_equal({}, params)
  end

  it "errors if JSON is not an object" do
    env = {
      "CONTENT_TYPE" => "application/json",
      "rack.input"   => StringIO.new('[2]'),
    }
    assert_raises(Rack::Committee::BadRequest) do
      Rack::Committee::RequestUnpacker.new(env).call
    end
  end

  it "errors on an unknown Content-Type" do
    env = {
      "CONTENT_TYPE" => "application/whats-this",
      "rack.input"   => StringIO.new('{"x":"y"}'),
    }
    assert_raises(Rack::Committee::BadRequest) do
      Rack::Committee::RequestUnpacker.new(env).call
    end
  end
end
