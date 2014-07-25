require_relative "test_helper"

require "stringio"

describe Committee::RequestValidator do
  before do
    @schema =
      JsonSchema.parse!(MultiJson.decode(File.read("./test/data/schema.json")))
    @schema.expand_references!
  end

  describe "POST" do
    before do
      # POST /apps/:id
      @link = @link = @schema.properties["app"].links[0]
      @request = Rack::Request.new({
        "CONTENT_TYPE"   => "application/json",
        "rack.input"     => StringIO.new("{}"),
        "REQUEST_METHOD" => "POST"
      })
    end

    it "passes through a valid request" do
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
      message = %{Invalid request.\n\n#/name: failed schema #/definitions/app/links/0/schema/properties/name: Expected string to match pattern "/^[a-z][a-z0-9-]{3,30}$/", value was: %@!.}
      assert_equal message, e.message
    end
  end

  describe "GET" do
    before do
      # GET /apps/search?query=:id
      @link = @link = @schema.properties["app"].links[5]
    end

    it "passes through a valid request" do
      @request = Rack::Request.new({
        "CONTENT_TYPE"   => "application/json",
        "rack.input"     => StringIO.new("{}"),
        "REQUEST_METHOD" => "GET",
        "QUERY_STRING"   => "query=heroku-api"
      })

      call({})
    end

    it "detects a parameter of the wrong pattern" do
      @request = Rack::Request.new({
        "CONTENT_TYPE"   => "application/json",
        "rack.input"     => StringIO.new("{}"),
        "REQUEST_METHOD" => "GET",
        "QUERY_STRING"   => "query=$@!"
      })

      e = assert_raises(Committee::InvalidRequest) do
        call({})
      end
      message = %{Invalid request.\n\n#/query: failed schema #/definitions/app/links/5/schema/properties/query: Expected string to match pattern "/^[a-z][a-z0-9-]{3,30}$/", value was: $@!.}
      assert_equal message, e.message
    end

    it "detects missing parameters" do
      @request = Rack::Request.new({
        "CONTENT_TYPE"   => "application/json",
        "rack.input"     => StringIO.new("{}"),
        "REQUEST_METHOD" => "GET"
      })

      e = assert_raises(Committee::InvalidRequest) do
        call({})
      end
      message = %{Invalid request.\n\n#: failed schema #/definitions/app/links/5/schema: Missing required keys "query" in object; keys are "".}
      assert_equal message, e.message
    end
  end

  private

  def call(data)
    Committee::RequestValidator.new(@link).call(@request, data)
  end
end
