require_relative "test_helper"

describe Committee::ResponseGenerator do
  before do
    @schema = JsonSchema.parse!(hyper_schema_data)
    @schema.expand_references!
    # GET /apps/:id
    @get_link = @link = @schema.properties["app"].links[2]
    # GET /apps
    @list_link = @schema.properties["app"].links[3]
  end

  it "generates string properties" do
    data = call
    assert data["name"].is_a?(String)
  end

  it "generates non-string properties" do
    data = call
    assert_includes [FalseClass, TrueClass], data["maintenance"].class
  end

  it "wraps list data in an array" do
    @link = @list_link

    @link.rel = nil

    data = call
    assert data.is_a?(Array)
  end

  it "wraps list data tagged with rel 'instances' in an array" do
    @link = @list_link
    data = call

    @link.parent = nil
    @link.target_schema = nil

    # We're testing for legacy behavior here: even without a `targetSchema` as
    # long as `rel` is set to `instances` we still wrap the the result in an
    # array.
    assert_equal "instances", @list_link.rel

    assert data.is_a?(Array)
  end

  it "errors with no known route for generation" do
    @link = @get_link

    # tweak the schema so that it can't be generated
    property = @schema.properties["app"].properties["maintenance"]
    property.data["example"] = nil
    property.type = []

    e = assert_raises(RuntimeError) do
      call
    end

    expected = <<-eos.gsub(/\n +/, "").strip
      At "#/definitions/app/properties/maintenance": no "example" attribute and 
      "null" is not allowed; don't know how to generate property.
    eos
    assert_equal expected, e.message
  end

  def call
    # hyper-schema link should be dropped into driver wrapper before it's used
    link = Committee::Drivers::HyperSchema::Link.new(@link)
    Committee::ResponseGenerator.new.call(link)
  end
end
