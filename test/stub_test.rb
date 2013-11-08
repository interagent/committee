require_relative "test_helper"

App = Rack::Builder.new {
  use Rack::Committee::Stub, schema: File.read("./test/data/schema.json")
  run lambda { |_|
    [200, {}, []]
  }
}

describe Rack::Committee::ParamValidation do
  include Rack::Test::Methods

  def app
    App
  end

  it "responds with a stubbed response" do
    get "/apps"
    assert_equal 200, last_response.status
    data = MultiJson.decode(last_response.body)
    assert_equal valid_app.keys.sort, data.keys.sort
  end

  def valid_app
    {
      "archived_at"                    => "",
      "buildpack_provided_description" => "",
      "created_at"                     => "",
      "id"                             => "",
      "git_url"                        => "",
      "maintenance"                    => "",
      "name"                           => "",
      "owner"                          => {
        "email"                        => "",
        "id"                           => "",
      },
      "region"                         => {
        "id"                           => "",
        "name"                         => "",
      },
      "released_at"                    => "",
      "repo_size"                      => "",
      "slug_size"                      => "",
      "stack"                          => {
        "id"                           => "",
        "name"                         => "",
      },
      "updated_at"                     => "",
      "web_url"                        => "",
    }
  end
end
