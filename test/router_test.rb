require_relative "test_helper"

describe Rack::Committee::Router do
  before do
    @schemata = { "schema/app" => MultiJson.decode(File.read("./test/schema.json")) }
    @router = Rack::Committee::Router.new(@schemata)
  end

  it "builds routes without parameters" do
    #assert_equal %r{/apps}.to_s, @routes["GET"][1][0].to_s
    assert @router.routes?("GET", "/apps")
  end

  it "builds routes with parameters" do
    #assert_equal %r{/apps/([^\/]+)}.to_s, @routes["GET"][0][0].to_s
    assert @router.routes?("GET", "/apps/123")
  end
end
