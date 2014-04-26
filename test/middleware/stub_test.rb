require_relative "../test_helper"

describe Committee::Middleware::Stub do
  include Rack::Test::Methods

  def app
    @app
  end

  it "responds with a stubbed response" do
    @app = new_rack_app
    get "/apps/heroku-api"
    assert_equal 200, last_response.status
    data = MultiJson.decode(last_response.body)
    assert_equal ValidApp.keys.sort, data.keys.sort
  end

  it "takes a prefix" do
    @app = new_rack_app(prefix: "/v1")
    get "/v1/apps/heroku-api"
    assert_equal 200, last_response.status
    data = MultiJson.decode(last_response.body)
    assert_equal ValidApp.keys.sort, data.keys.sort
  end

  private

  def new_rack_app(options = {})
    options = {
      schema: File.read("./test/data/schema.json")
    }.merge(options)
    Rack::Builder.new {
      use Committee::Middleware::Stub, options
      run lambda { |_|
        [200, {}, []]
      }
    }
  end
end
