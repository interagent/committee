require_relative "test_helper"

describe Committee::ResponseGenerator do
  before do
    @schema =
      JsonSchema.parse!(MultiJson.decode(File.read("./test/data/schema.json")))
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
    data = call
    assert data.is_a?(Array)
  end

  def call
    Committee::ResponseGenerator.new.call(@link)
  end
end
