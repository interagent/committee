require_relative "test_helper"

describe Rack::Committee::ParamValidation do
  include Rack::Test::Methods

  ParamValidationApp = Rack::Builder.new {
    use Rack::Committee::Stub, schema: File.read("./test/data/schema.json")
    run lambda { |_|
      [200, {}, []]
    }
  }

  def app
    ParamValidationApp
  end

  it "responds with a stubbed response" do
    get "/apps"
    assert_equal 200, last_response.status
    data = MultiJson.decode(last_response.body)
    assert_equal ValidApp.keys.sort, data.keys.sort
  end
end
