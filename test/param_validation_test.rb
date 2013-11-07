require_relative "test_helper"

App = Rack::Builder.new {
  use Rack::Committee::ParamValidation, schema: File.read("./test/schema.json")
  run lambda { |_|
    [200, {}, []]
  }
}

describe Rack::Committee::ParamValidation do
  include Rack::Test::Methods

  def app
    App
  end

  it "x" do
    post "/apps"
  end
end
