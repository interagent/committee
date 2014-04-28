require_relative "test_helper"

describe Committee::Router do
  before do
    data = File.read("./test/data/schema.json")
    schema = Committee::Schema.new(data)
    @router = Committee::Router.new(schema)
  end

  it "builds routes without parameters" do
    refute_nil @router.routes?("GET", "/apps")[0]
  end

  it "builds routes with parameters" do
    refute_nil @router.routes?("GET", "/apps/123")[0]
  end

  it "doesn't match anything on a /" do
    assert_nil @router.routes?("GET", "/")[0]
  end

  it "takes a prefix" do
    # this is a sociopathic example
    refute_nil @router.routes?("GET", "/kpi/apps/123", prefix: "/kpi")[0]
  end
end
