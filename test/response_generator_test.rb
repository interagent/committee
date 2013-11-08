require_relative "test_helper"

describe Rack::Committee::ResponseGenerator do
  before do
    data = MultiJson.decode(File.read("./test/schema.json"))
    app_schema = data["definitions"]["app"]
    @generator = Rack::Committee::ResponseGenerator.new(app_schema)
  end

  it "generates string properties" do
    data = @generator.call
    assert data["name"].is_a?(String)
  end
end
