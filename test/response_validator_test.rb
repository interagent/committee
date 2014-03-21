require_relative "test_helper"

describe Committee::ResponseValidator do
  before do
    @data = ValidApp.dup
    @schema = Committee::Schema.new(File.read("./test/data/schema.json"))
    # GET /apps/:id
    @link_schema = @schema["app"]["links"][2]
  end

  it "passes through a valid response" do
    call
  end

  it "passes through a valid list response" do
    @data = [@data]
    # GET /apps
    @link_schema = @schema["app"]["links"][3]
    call
  end

  it "passes through a valid list response with non-default title" do
    @data = [@data]
    @link_schema = @schema["app"]["links"][4]
    call
  end

  it "detects an improperly formatted list response" do
    # GET /apps
    @link_schema = @schema["app"]["links"][3]
    e = assert_raises(Committee::InvalidResponse) { call }
    message = "List endpoints must return an array of objects."
    assert_equal message, e.message
  end

  it "detects missing keys in response" do
    @data.delete("name")
    e = assert_raises(Committee::InvalidResponse) { call }
    message = %r{Missing keys in response: name.}
    assert_match message, e.message
  end

  it "detects extra keys in response" do
    @data.merge!("tier" => "important")
    e = assert_raises(Committee::InvalidResponse) { call }
    message = %r{Extra keys in response: tier.}
    assert_match message, e.message
  end

  it "detects mismatched types" do
    @data.merge!("maintenance" => "not-bool")
    e = assert_raises(Committee::InvalidResponse) { call }
    message = %{Invalid type at "maintenance": expected not-bool to be ["boolean"] (was: ["string"]).}
    assert_equal message, e.message
  end

  it "detects bad formats" do
    @data.merge!("id" => "123")
    e = assert_raises(Committee::InvalidFormat) { call }
    message = %{Invalid format at "id": expected "123" to be "uuid".}
    assert_equal message, e.message
  end

  it "detects bad patterns" do
    @data.merge!("name" => "%@!")
    e = assert_raises(Committee::InvalidResponse) { call }
    message = %{Invalid pattern at "name": expected %@! to match "(?-mix:^[a-z][a-z0-9-]{3,30}$)".}
    assert_equal message, e.message
  end

  it "accepts date-time format without milliseconds" do
    validator = Committee::ResponseValidator.new(
      @data,
      @schema,
      @link_schema,
      @schema["app"])

    value = "2014-03-10T00:00:00Z"
    assert_nil validator.check_format!("date-time", value, ["example"])
  end

  it "accepts date-time format with milliseconds" do
    validator = Committee::ResponseValidator.new(
      @data,
      @schema,
      @link_schema,
      @schema["app"])

    value = "2014-03-10T00:00:00.123Z"
    assert_nil validator.check_format!("date-time", value, ["example"])
  end

  private

  def call
    Committee::ResponseValidator.new(
      @data,
      @schema,
      @link_schema,
      @schema["app"]
    ).call
  end
end
