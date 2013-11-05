require_relative "test_helper"

describe Rack::Committee::RoutesBuilder do
  before do
    @schemata = { "schema/app" => MultiJson.decode(File.read("./test/schema.json")) }
    @routes = Rack::Committee::RoutesBuilder.new(@schemata).call
  end

  it "builds routes without parameters" do
    assert_equal %r{/apps}.to_s, @routes["GET"][1][0].to_s
  end

  it "builds routes with parameters" do
    assert_equal %r{/apps/([^\/]+)}.to_s, @routes["GET"][0][0].to_s
  end
end
