require_relative "test_helper"

describe Committee::QueryHashCoercer do
  before do
    @schema =
      JsonSchema.parse!(JSON.parse(File.read("./test/data/schema.json")))
    @schema.expand_references!
    # GET /search/apps
    @link = @link = @schema.properties["app"].links[5]
  end

  it "doesn't coerce params not in the schema" do
    data = {"owner" => "admin"}
    assert_equal({}, call(data))
  end

  it "simply skips string" do
    data = {"name" => "foo"}
    assert_equal({}, call(data))
  end

  it "coerces valid boolean value" do
    data = {"deleted" => "true"}
    assert_equal({"deleted" => true}, call(data))
    data = {"deleted" => "false"}
    assert_equal({"deleted" => false}, call(data))
  end

  it "coerces valid integer value" do
    data = {"per_page" => "3"}
    assert_equal({"per_page" => 3}, call(data))
    data = {"per_page" => "3.5"}
    assert_equal({}, call(data))
    data = {"per_page" => "false"}
    assert_equal({}, call(data))
  end

  it "coerces valid number value" do
    data = {"threshold" => "3"}
    assert_equal({"threshold" => 3.0}, call(data))
    data = {"threshold" => "3.5"}
    assert_equal({"threshold" => 3.5}, call(data))
    data = {"threshold" => "false"}
    assert_equal({}, call(data))
  end

  it "coerces valid null value" do
    data = {"threshold" => ""}
    assert_equal({"threshold" => nil}, call(data))
  end

  private

  def call(data)
    Committee::QueryHashCoercer.new(data, @link.schema).call
  end
end
