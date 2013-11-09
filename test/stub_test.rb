require_relative "test_helper"

describe Committee::ParamValidation do
  include Rack::Test::Methods

  ParamValidationApp = Rack::Builder.new {
    use Committee::Stub, schema: File.read("./test/data/schema.json")
    run lambda { |_|
      [200, {}, []]
    }
  }

  def app
    ParamValidationApp
  end

  it "responds with a stubbed response" do
    get "/apps/heroku-api"
    assert_equal 200, last_response.status
    data = MultiJson.decode(last_response.body)
    assert_equal ValidApp.keys.sort, data.keys.sort
  end
end
