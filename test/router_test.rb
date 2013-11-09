require_relative "test_helper"

describe Committee::Router do
  before do
    data = File.read("./test/data/schema.json")
    schema = Committee::Schema.new(data)
    @router = Committee::Router.new(schema)
  end

  it "builds routes without parameters" do
    assert @router.routes?("GET", "/apps")
  end

  it "builds routes with parameters" do
    assert @router.routes?("GET", "/apps/123")
  end
end
