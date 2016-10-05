require_relative "../test_helper"

describe Committee::Drivers::HyperSchema do
  before do
    @driver = Committee::Drivers::HyperSchema.new
  end

  it "builds a routing table" do
    data = JSON.parse(File.read("./test/data/hyperschema/heroku.json"))
    schema = JsonSchema.parse!(data)
    schema.expand_references!

    routes = @driver.build_routes(schema)
    assert_kind_of Hash, routes
    refute routes.empty?
    assert(routes.keys.all? { |m|
      ["DELETE", "GET", "PATCH", "POST", "PUT"].include?(m)
    })

    routes.each do |(_, method_routes)|
      method_routes.each do |regex, link|
        assert_kind_of Regexp, regex
        assert_kind_of Committee::Drivers::HyperSchema::Link, link
      end
    end
  end

  it "parses a hyper-schema" do
    schema = @driver.parse({})
    assert_kind_of JsonSchema::Schema, schema
  end
end

describe Committee::Drivers::HyperSchema::Link do
  before do
    @hyper_schema_link = JsonSchema::Schema::Link.new
    @hyper_schema_link.enc_type = "application/x-www-form-urlencoded"
    @hyper_schema_link.href = "/apps"
    @hyper_schema_link.media_type = "application/json"
    @hyper_schema_link.method = "GET"
    @hyper_schema_link.parent = { "title": "parent" }
    @hyper_schema_link.rel = "instances"
    @hyper_schema_link.schema = { "title": "input" }
    @hyper_schema_link.target_schema = { "title": "target" }

    @link = Committee::Drivers::HyperSchema::Link.new(@hyper_schema_link)
  end

  it "proxies #enc_type" do
    assert_equal "application/x-www-form-urlencoded", @link.enc_type
  end

  it "proxies #href" do
    assert_equal "/apps", @link.href
  end

  it "proxies #media_type" do
    assert_equal "application/json", @link.media_type
  end

  it "proxies #method" do
    assert_equal "GET", @link.method
  end

  it "proxies #rel" do
    assert_equal "instances", @link.rel
  end

  it "proxies #schema" do
    assert_equal @hyper_schema_link.schema, @link.schema
  end

  it "generates 200 #status_success for non-create" do
    assert_equal 200, @link.status_success
  end

  it "generates 201 #status_success for create" do
    @hyper_schema_link.rel = "create"
    assert_equal 201, @link.status_success
  end

  it "prefers to proxy #target_schema" do
    assert_equal @hyper_schema_link.target_schema, @link.target_schema
  end

  it "falls back to parent for #target_schema" do
    @hyper_schema_link.target_schema = nil
    assert_equal @hyper_schema_link.parent, @link.target_schema
  end
end
