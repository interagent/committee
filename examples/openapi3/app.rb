require "committee"
require "json"
require "securerandom"
require "sinatra/base"
require "yaml"

class App < Sinatra::Base
  SCHEMA_PATH = File.expand_path("../openapi.yaml", __FILE__)
  use Committee::Middleware::RequestValidation, schema_path: SCHEMA_PATH, strict: true, raise: true
  use Committee::Middleware::ResponseValidation, schema_path: SCHEMA_PATH

  # This handler is called into, but its response is ignored.
  get "/apps" do
  end

  # This handler suppresses the stubbed response and returns its own.
  get "/posts" do
    content_type :json
    status 204
  end

  post "/dont_allow_additional_parameter" do
    content_type :json
    status 204
  end
end

if __FILE__ == $0
  App.run! port: 5000
end
