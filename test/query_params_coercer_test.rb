require_relative "test_helper"

describe Committee::QueryParamsCoercer do
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

  it "skips values for string param" do
    data = {"name" => "foo"}
    assert_equal({}, call(data))
  end

  it "coerces valid values for boolean param" do
    data = {"deleted" => "true"}
    assert_equal({"deleted" => true}, call(data))
    data = {"deleted" => "false"}
    assert_equal({"deleted" => false}, call(data))
  end

  it "skips invalid values for boolean param" do
    data = {"deleted" => "foo"}
    assert_equal({}, call(data))
  end

  it "coerces valid values for integer param" do
    data = {"per_page" => "3"}
    assert_equal({"per_page" => 3}, call(data))
  end

  it "skips invalid values for integer param" do
    data = {"per_page" => "3.5"}
    assert_equal({}, call(data))
    data = {"per_page" => "false"}
    assert_equal({}, call(data))
    data = {"per_page" => ""}
    assert_equal({}, call(data))
  end

  it "coerces valid values for number param" do
    data = {"threshold" => "3"}
    assert_equal({"threshold" => 3.0}, call(data))
    data = {"threshold" => "3.5"}
    assert_equal({"threshold" => 3.5}, call(data))
  end

  it "skips invalid values for number param" do
    data = {"threshold" => "false"}
    assert_equal({}, call(data))
  end

  it "coerces valid values for null param" do
    data = {"threshold" => ""}
    assert_equal({"threshold" => nil}, call(data))
  end

  private

  def call(data)
    Committee::QueryParamsCoercer.new(data, @link.schema).call
  end
end
