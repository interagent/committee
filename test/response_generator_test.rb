require_relative "test_helper"

describe Rack::Committee::ResponseGenerator do
  before do
    schema = Rack::Committee::Schema.new(File.read("./test/data/schema.json"))
    @generator = Rack::Committee::ResponseGenerator.new(schema, schema["app"])
  end

  it "generates string properties" do
    data = @generator.call
    assert data["name"].is_a?(String)
  end

  it "generates non-string properties" do
    data = @generator.call
    assert [FalseClass, TrueClass].include?(data["maintenance"].class)
  end
end
