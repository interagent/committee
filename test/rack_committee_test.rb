require_relative "test_helper"

App = Rack::Builder.new {
  use Rack::Committee, schema: File.read("./test/schema.json")
  run lambda { |_|
    [200, {}, []]
  }
}

describe Rack::Committee do
  include Rack::Test::Methods

  def app
    App
  end

  it "x" do
    get "/apps"
  end
end
