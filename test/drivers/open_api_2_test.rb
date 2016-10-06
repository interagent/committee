require_relative "../test_helper"

describe Committee::Drivers::OpenAPI2 do
  before do
    @driver = Committee::Drivers::OpenAPI2.new
  end

  it "parses an OpenAPI 2 spec" do
    spec = @driver.parse(open_api_2_data)
    assert_kind_of Committee::Drivers::OpenAPI2::Spec, spec
    assert_kind_of JsonSchema::Schema, spec.definitions

    assert_kind_of Hash, spec.routes
    refute spec.routes.empty?
    assert(spec.routes.keys.all? { |m|
      ["DELETE", "GET", "PATCH", "POST", "PUT"].include?(m)
    })

    spec.routes.each do |(_, method_routes)|
      method_routes.each do |regex, link|
        assert_kind_of Regexp, regex
        assert_kind_of Committee::Drivers::OpenAPI2::Link, link

        # verify that we've correct generated a parameters schema for each link
        if link.target_schema
          assert_kind_of JsonSchema::Schema, link.schema if link.schema
        end

        if link.target_schema
          assert_kind_of JsonSchema::Schema, link.target_schema
        end
      end
    end
  end

  it "refuses to parse other version of OpenAPI" do
    data = open_api_2_data
    data['swagger'] = '3.0'
    e = assert_raises(ArgumentError) do
      @driver.parse(data)
    end
    assert_equal "Committee: driver requires OpenAPI 2.0.", e.message
  end

  it "refuses to parse a spec without mandatory fields" do
    data = open_api_2_data
    data['definitions'] = nil
    e = assert_raises(ArgumentError) do
      @driver.parse(data)
    end
    assert_equal "Committee: no definitions section in spec data.", e.message
  end
end

describe Committee::Drivers::OpenAPI2::Link do
  before do
    @link = Committee::Drivers::OpenAPI2::Link.new
    @link.enc_type = "application/x-www-form-urlencoded"
    @link.href = "/apps"
    @link.media_type = "application/json"
    @link.method = "GET"
    @link.status_success = 200
    @link.schema = { "title" => "input" }
    @link.target_schema = { "title" => "target" }
  end

  it "uses set #enc_type" do
    assert_equal "application/x-www-form-urlencoded", @link.enc_type
  end

  it "uses set #href" do
    assert_equal "/apps", @link.href
  end

  it "uses set #media_type" do
    assert_equal "application/json", @link.media_type
  end

  it "uses set #method" do
    assert_equal "GET", @link.method
  end

  it "proxies #rel" do
    e = assert_raises do
      @link.rel
    end
    assert_equal "Committee: rel not implemented for OpenAPI", e.message
  end

  it "uses set #schema" do
    assert_equal({ "title" => "input" }, @link.schema)
  end

  it "uses set #status_success" do
    assert_equal 200, @link.status_success
  end

  it "uses set #target_schema" do
    assert_equal({ "title" => "target" }, @link.target_schema)
  end
end

describe Committee::Drivers::OpenAPI2::ParameterSchemaBuilder do
  before do
  end

  it "reflects a basic type into a schema" do
    data = {
      "parameters" => [
        {
          "name" => "limit",
          "type" => "integer",
        }
      ]
    }
    schema = call(data)

    assert_equal ["limit"], schema.properties.keys
    assert_equal [], schema.required
    assert_equal ["integer"], schema.properties["limit"].type
  end

  it "reflects a required property into a schema" do
    data = {
      "parameters" => [
        {
          "name" => "limit",
          "required" => true,
        }
      ]
    }
    schema = call(data)

    assert_equal ["limit"], schema.required
  end

  it "reflects an array with an items schema into a schema" do
    data = {
      "parameters" => [
        {
          "name" => "tags",
          "type" => "array",
          "items" => {
            "type" => "string"
          }
        }
      ]
    }
    schema = call(data)

    assert_equal ["array"], schema.properties["tags"].type
    assert_equal({ "type" => "string" }, schema.properties["tags"].items)
  end

  it "requires that certain fields are present" do
    data = {
      "parameters" => [
        {
        }
      ]
    }
    e = assert_raises ArgumentError do
      call(data)
    end
    assert_equal "Committee: no name section in link data.", e.message
  end

  def call(data)
    Committee::Drivers::OpenAPI2::ParameterSchemaBuilder.new(data).call
  end
end
