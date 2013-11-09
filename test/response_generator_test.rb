require_relative "test_helper"

describe Rack::Committee::ResponseGenerator do
  before do
    @schema = Rack::Committee::Schema.new(File.read("./test/data/schema.json"))
    @generator = Rack::Committee::ResponseGenerator.new(
      @schema,
      @schema["app"],
      @schema["app"]["links"][0]
    )
  end

  it "generates string properties" do
    data = @generator.call
    assert data["name"].is_a?(String)
  end

  it "generates non-string properties" do
    data = @generator.call
    assert [FalseClass, TrueClass].include?(data["maintenance"].class)
  end

  it "wraps list data in an array" do
    @generator = Rack::Committee::ResponseGenerator.new(
      @schema,
      @schema["app"],
      @schema["app"]["links"][3]
    )
    data = @generator.call
    assert data.is_a?(Array)
  end
end
