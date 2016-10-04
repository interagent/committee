require_relative "test_helper"

describe Committee::Router do
  it "builds routes without parameters" do
    refute_nil router.find_link("GET", "/apps")
  end

  it "builds routes with parameters" do
    refute_nil router.find_link("GET", "/apps/123")
  end

  it "doesn't match anything on a /" do
    assert_nil router.find_link("GET", "/")
  end

  it "takes a prefix" do
    # this is a sociopathic example
    assert router(prefix: "/kpi").find_link("GET", "/kpi/apps/123")
  end

  it "includes all paths without a prefix" do
    assert router.includes?("/")
    assert router.includes?("/apps")
  end

  it "only includes the prefix path with a prefix" do
    refute router(prefix: "/kpi").includes?("/")
    assert router(prefix: "/kpi").includes?("/kpi")
    assert router(prefix: "/kpi").includes?("/kpi/apps")
  end

  def router(options = {})
    data = JSON.parse(File.read("./test/data/hyperschema/heroku.json"))
    schema = JsonSchema.parse!(data)
    schema.expand_references!
    Committee::Router.new(schema, options.merge(
      driver: Committee::Drivers::HyperSchema.new
    ))
  end
end
