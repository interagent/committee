require_relative "test_helper"

require "stringio"

describe Committee::RequestValidator do
  before do
    @schema = JsonSchema.parse!(hyper_schema_data)
    @schema.expand_references!
    # POST /apps/:id
    @link = @link = @schema.properties["app"].links[0]
    @request = Rack::Request.new({
      "CONTENT_TYPE"   => "application/json",
      "rack.input"     => StringIO.new("{}"),
      "REQUEST_METHOD" => "POST"
    })
  end

  it "passes through a valid request with Content-Type options" do
    @headers = { "Content-Type" => "application/json; charset=utf-8" }
    call({})
  end

  it "passes through a valid request" do
    data = {
      "name" => "heroku-api",
    }
    call(data)
  end

  it "passes through a valid request with Content-Type options" do
    @request =
      Rack::Request.new({
      "CONTENT_TYPE" => "application/json; charset=utf-8",
      "rack.input"   => StringIO.new("{}"),
    })
    data = {
      "name" => "heroku-api",
    }
    call(data)
  end

  it "detects an invalid request Content-Type" do
    e = assert_raises(Committee::InvalidRequest) {
      @request =
        Rack::Request.new({
          "CONTENT_TYPE" => "application/x-www-form-urlencoded",
          "rack.input"   => StringIO.new("{}"),
        })
      call({})
    }
    message =
      %{"Content-Type" request header must be set to "application/json".}
    assert_equal message, e.message
  end

  it "allows skipping content_type check" do
    @request =
      Rack::Request.new({
        "CONTENT_TYPE" => "application/x-www-form-urlencoded",
        "rack.input"   => StringIO.new("{}"),
      })
    call({}, check_content_type: false)
  end

  it "detects an missing parameter in GET requests" do
    # GET /apps/search?query=...
    @link = @link = @schema.properties["app"].links[5]
    @request = Rack::Request.new({})
    e = assert_raises(Committee::InvalidRequest) do
      call({})
    end
    message =
      %{Invalid request.\n\n#: failed schema #/definitions/app/links/5/schema: "query" wasn't supplied.}
    assert_equal message, e.message
  end

  it "allows an invalid Content-Type with an empty body" do
    @request =
      Rack::Request.new({
        "CONTENT_TYPE" => "application/x-www-form-urlencoded",
        "rack.input"   => StringIO.new(""),
      })
    call({})
  end

  it "detects a parameter of the wrong pattern" do
    data = {
      "name" => "%@!"
    }
    e = assert_raises(Committee::InvalidRequest) do
      call(data)
    end
    message = %{Invalid request.\n\n#/name: failed schema #/definitions/app/links/0/schema/properties/name: %@! does not match /^[a-z][a-z0-9-]{3,30}$/.}
    assert_equal message, e.message
  end

  private

  def call(data, options={})
    # hyper-schema link should be dropped into driver wrapper before it's used
    link = Committee::Drivers::HyperSchema::Link.new(@link)
    Committee::RequestValidator.new(link, options).call(@request, data)
  end
end
