require_relative "../test_helper"

describe Committee::Middleware::Stub do
  include Rack::Test::Methods

  def app
    @app ||= new_rack_app
  end

  describe "GET on a collection" do
    it "starts with an empty collection" do
      get "/apps"
      assert_equal 200, last_response.status
      data = MultiJson.decode(last_response.body)
      assert_equal [], data
    end
  end

  describe "GET on a resource" do
    it "renders a 404 if resource is not in memory" do
      get "/apps/foo"
      assert_equal 404, last_response.status
    end
  end

  describe "POST to create a new resource" do
    it "renders a 201" do
      params = { name: "foo" }
      post "/apps", MultiJson.encode(params)
      assert_equal 201, last_response.status
      data = MultiJson.decode(last_response.body)
      assert_equal "foo", data["name"]
    end

    it "subsequently lists it" do
      params = { name: "foo" }
      post "/apps", MultiJson.encode(params)
      assert_equal 201, last_response.status
      get "/apps"
      assert_equal 200, last_response.status
      data = MultiJson.decode(last_response.body)
      assert_equal "foo", data.first["name"]
    end
  end

  private

  def new_rack_app(options = {})
    options = {
      schema: File.read("./test/data/schema.json")
    }.merge(options)
    Rack::Builder.new {
      use Committee::Middleware::MemoryStub, options
      run lambda { |env|
        [404, {}, ["Not attended by the stub"]]
      }
    }
  end
end
