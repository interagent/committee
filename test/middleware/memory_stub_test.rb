require_relative "../test_helper"

describe Committee::Middleware::Stub do
  include Rack::Test::Methods

  def app
    @app
  end

  it "starts with an empty collection" do
    @app = new_rack_app
    get "/apps"
    assert_equal 200, last_response.status
    data = MultiJson.decode(last_response.body)
    assert_equal [], data
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
